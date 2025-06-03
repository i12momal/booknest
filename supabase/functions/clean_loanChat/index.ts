import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Variables de entorno
const SUPABASE_URL = "https://ejqvfrjilmxuqrxnrvbs.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqcXZmcmppbG14dXFyeG5ydmJzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MDY4MDQ3NywiZXhwIjoyMDU2MjU2NDc3fQ.uW_jpz89wCsKQ5gY1-0xql5Vj2F7X7ZqeUXJQUeBSCA";

// Verificación
console.log("SUPABASE_URL:", SUPABASE_URL);
console.log("SUPABASE_SERVICE_ROLE_KEY:", SUPABASE_SERVICE_ROLE_KEY);

serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Paso 1: Buscar registros que deben eliminarse
    const { data: chatsToDelete, error: fetchError } = await supabase
      .from("LoanChat")
      .select("id")
      .eq("deleteByOwner", true)
      .eq("deleteByHolder", true);

    if (fetchError) {
      console.log("Error al buscar chats:", fetchError);
      return new Response("Error al buscar chats", { status: 500 });
    }

    if (!chatsToDelete || chatsToDelete.length === 0) {
      return new Response("No hay chats para eliminar", { status: 200 });
    }

    const idsToDelete = chatsToDelete.map((chat: { id: string }) => chat.id);

    // Paso 2: Eliminar los registros por ID
    const { error: deleteError } = await supabase
      .from("LoanChat")
      .delete()
      .in("id", idsToDelete);

    if (deleteError) {
      console.log("Error al eliminar chats:", deleteError);
      return new Response("Error al eliminar chats", { status: 500 });
    }

    return new Response(`Se eliminaron ${idsToDelete.length} chats`, { status: 200 });
  } catch (e) {
    console.error("Excepción durante el proceso:", e);
    return new Response("Error interno del servidor", { status: 500 });
  }
});
