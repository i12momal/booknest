import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Cargar las variables de entorno desde el archivo .env
const SUPABASE_URL = "https://ejqvfrjilmxuqrxnrvbs.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXZmcmppbG14dXFyeG5ydmJzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MDY4MDQ3NywiZXhwIjoyMDU2MjU2NDc3fQ.uW_jpz89wCsKQ5gY1-0xql5Vj2F7X7ZqeUXJQUeBSCA";

// Verificamos que las variables se han cargado correctamente
console.log("SUPABASE_URL:", SUPABASE_URL);
console.log("SUPABASE_SERVICE_ROLE_KEY:", SUPABASE_SERVICE_ROLE_KEY);


// Función de creación de notificación
async function createNotification(createNotificationViewModel: { userId: string, type: string, relatedId: number, message: string, read: boolean }) {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Crear el registro en la tabla Notification
    console.log("Creando registro en la tabla Notification...");
    const notificationData = {
      'userId': createNotificationViewModel.userId,
      'type': createNotificationViewModel.type,
      'relatedId': createNotificationViewModel.relatedId,
      'message': createNotificationViewModel.message,
      'read': createNotificationViewModel.read
    };
    console.log("Datos a insertar: ", notificationData);

    const response = await supabase.from('Notifications').insert(notificationData).select().single();

    console.log("Respuesta de la inserción en Notification: ", response);

    if (response != null) {
      console.log("Notificación registrada exitosamente");
      return {
        'success': true,
        'message': 'Notificación registrada exitosamente',
        'data': response
      };
    } else {
      console.log("Error: No se pudo crear el registro en la tabla Notification");
      return { 'success': false, 'message': 'Error al registrar la notificación' };
    }
  } catch (ex) {
    console.log("Error en createNotification: ", ex);
    return { 'success': false, 'message': 'Se ha producido una excepción' };
  }
}




serve(async (_req) => {
  try {
    // Usamos las variables cargadas de .env
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: loans, error } = await supabase
      .from("Loan")
      .select("*")
      .eq("state", "Aceptado");

    if (error) {
      console.error("Error fetching loans:", error);
      return new Response("Error fetching loans", { status: 500 });
    }

    const now = new Date();

    // Función para normalizar fechas a 'YYYY-MM-DD'
    const normalizeDate = (date: Date) => date.toISOString().split("T")[0];
    const nowDateStr = normalizeDate(now);

    // El cronjob se ejecuta a las 23:59, por lo tanto, si la fecha final es hoy o anterior, debe marcarse como "Devuelto".
    for (const loan of loans) {
      const loanEndDate = new Date(loan.endDate + "Z");  // Asegura que se trate como UTC
      const loanDateStr = normalizeDate(loanEndDate);
      console.log(`Loan ID: ${loan.id}, Loan End Date: ${loanDateStr}, Today: ${nowDateStr}`);

      // Si la fecha de finalización es hoy o antes de hoy, lo marcamos como "Devuelto"
      if (loanDateStr <= nowDateStr) {
        console.log(`Updating loan ID: ${loan.id} to "Devuelto"`);
        
        const { error: updateError } = await supabase
          .from("Loan")
          .update({ state: "Devuelto" })
          .eq("id", loan.id);
    
        if (updateError) {
          console.error(`Error updating loan ${loan.id}`, updateError);
          return new Response("Error updating loan", { status: 500 });
        } else {
          console.log(`Successfully updated loan ${loan.id} to "Devuelto"`);

          // Obtener el libro relacionado
          const bookId = loan.bookId;
          const bookResponse = await supabase
            .from('Book')
            .select('title')
            .eq('id', bookId)
            .single();
   
          if (bookResponse.error) {
            console.error(`Error fetching book details for loan ${loan.id}`);
            return new Response("Error fetching book details", { status: 500 });
          }

          const bookTitle = bookResponse.data.title;
          const ownerId = loan.ownerId;
          const bookFormat = loan.format;

          // Enviar notificación al propietario del libro
          const message = `Tu libro "${bookTitle}" en formato ${bookFormat} ha sido devuelto automáticamente.`;
          const createNotificationViewModel = {
            userId: ownerId,
            type: 'Préstamo Devuelto',
            relatedId: loan.id,
            message: message,
            read: false
          };

          const notificationResponse = await createNotification(createNotificationViewModel);

          if (!notificationResponse.success) {
            console.error("Error al registrar la notificación:", notificationResponse.message);
          } else {
            console.log("Notificación registrada exitosamente para el préstamo devuelto.");
          }
        }
      } else {
        console.log(`Loan ID: ${loan.id} is not overdue yet.`);
      }
    }

    return new Response("Checked and updated overdue loans", { status: 200 });

  } catch (e) {
    console.error('Error in cron job:', e);
    return new Response("Internal Server Error", { status: 500 });
  }
});
