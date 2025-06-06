import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Cargar las variables de entorno
const SUPABASE_URL = Deno.env.get("MY_SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("MY_SUPABASE_SERVICE_ROLE_KEY")!;

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
