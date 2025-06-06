import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Cargar las variables de entorno
const SUPABASE_URL = Deno.env.get("MY_SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("MY_SUPABASE_SERVICE_ROLE_KEY")!;

// Función de creación de notificación
async function createNotification(createNotificationViewModel: { userId: string, type: string, relatedId: number, message: string, read: boolean }) {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const notificationData = {
      userId: createNotificationViewModel.userId,
      type: createNotificationViewModel.type,
      relatedId: createNotificationViewModel.relatedId,
      message: createNotificationViewModel.message,
      read: createNotificationViewModel.read
    };

    const { data, error } = await supabase.from('Notifications').insert(notificationData).select().single();

    if (error) {
      console.log("Error al insertar notificación:", error);
      return { success: false, message: 'Error al registrar la notificación' };
    }

    return { success: true, message: 'Notificación registrada exitosamente', data };
  } catch (ex) {
    console.log("Excepción en createNotification:", ex);
    return { success: false, message: 'Se ha producido una excepción' };
  }
}

// Función para obtener los préstamos activos por formato de un libro
async function getActiveLoanForBookAndFormat(bookId: number, format: string): Promise<boolean> {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error } = await supabase
      .from('Loan')
      .select('id')
      .eq('bookId', bookId)
      .eq('format', format)
      .eq('state', 'Aceptado')
      .maybeSingle();

    return !!data;
  } catch (e) {
    console.log('Error al verificar préstamo activo:', e);
    return false;
  }
}

// Función que comprueba la disponiblidad de los formatos de un libro
async function areAllFormatsAvailable(bookId: number, formats: string[]): Promise<boolean> {
  try {
    for (const format of formats) {
      const hasActiveLoan = await getActiveLoanForBookAndFormat(bookId, format);
      if (hasActiveLoan) return false;
    }
    return true;
  } catch (e) {
    console.log('Error al verificar disponibilidad de formatos:', e);
    return false;
  }
}

// Función para eliminar un recordatorio
async function removeFromReminder(bookId: number, userId: string, format: string) {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    await supabase.from('Reminder')
      .delete()
      .eq('userId', userId)
      .eq('bookId', bookId)
      .eq('format', format);
  } catch (error) {
    console.log("Error al eliminar recordatorio:", error);
  }
}

serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: loans, error } = await supabase
      .from("Loan")
      .select("*")
      .eq("state", "Aceptado");

    if (error) return new Response("Error fetching loans", { status: 500 });

    const now = new Date();
    const normalizeDate = (date: Date) => date.toISOString().split("T")[0];
    const nowDateStr = normalizeDate(now);

    for (const loan of loans) {
      const loanEndDate = new Date(loan.endDate + "Z");
      const loanDateStr = normalizeDate(loanEndDate);

      if (loanDateStr <= nowDateStr) {
        // Solo aplicar devolución automática si es formato Digital
        if (loan.format !== "Digital") continue;
        
        await supabase.from("Loan").update({ state: "Devuelto" }).eq("id", loan.id);

        const bookResponse = await supabase
          .from('Book')
          .select('title, format')
          .eq('id', loan.bookId)
          .single();

        if (bookResponse.error) continue;

        const bookTitle = bookResponse.data.title;
        const bookFormat = loan.format;
        const ownerId = loan.ownerId;

        // Notificación
        await createNotification({
          userId: ownerId,
          type: 'Préstamo Devuelto',
          relatedId: loan.id,
          message: `Tu libro "${bookTitle}" en formato ${bookFormat} ha sido devuelto automáticamente.`,
          read: false
        });

        // Estado del libro
        await supabase.from("Book").update({ state: "Disponible" }).eq("id", loan.bookId);

        // Recordatorios
        const { data: reminders, error: reminderError } = await supabase
          .from('Reminder')
          .select('userId')
          .eq('bookId', loan.bookId)
          .eq('format', bookFormat)
          .eq('notified', false);

        if (!reminderError && reminders && reminders.length > 0) {
          for (const row of reminders) {
            const userId = row.userId;

            await createNotification({
              userId,
              type: 'Recordatorio',
              relatedId: loan.bookId,
              message: `El libro "${bookTitle}" en formato ${bookFormat} vuelve a estar disponible.`,
              read: false
            });
          }
        }

        // Verificación y eliminación de recordatorios si todos los formatos están disponibles
        const bookFormats = bookResponse.data.format.split(',').map((f: string) => f.trim());
        const allAvailable = await areAllFormatsAvailable(loan.bookId, bookFormats);

        if (allAvailable) {
          for (const f of bookFormats) {
            for (const row of reminders || []) {
              await removeFromReminder(loan.bookId, row.userId, f);
            }
          }
        }
      }
    }

    return new Response("Checked and updated overdue loans", { status: 200 });
  } catch (e) {
    console.error('Error en el proceso:', e);
    return new Response("Internal Server Error", { status: 500 });
  }
});
