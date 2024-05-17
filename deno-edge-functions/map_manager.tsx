import { Application, Router, send } from "https://deno.land/x/oak/mod.ts";
import { oakCors } from "https://deno.land/x/cors/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.5.0";

console.log("Hello from Map Manager!");

const router = new Router();

function generateHexHash(length) {
    // Generate random bytes
    const bytes = new Uint8Array(length / 2);
    crypto.getRandomValues(bytes);

    // Convert each byte to a hexadecimal string and concatenate them
    return '0x' + Array.from(bytes, byte => byte.toString(16).padStart(2, '0')).join('');
}

router
  .get("/all", async (context) => {

    const supabase = createClient(
      // Supabase API URL - env var exported by default.
      Deno.env.get("SUPABASE_URL") ?? "",
      // Supabase API ANON KEY - env var exported by default.
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      // Create client with Auth context of the user that called the function.
      // This way your row-level-security (RLS) policies are applied.
      // { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // 1. create a item in bodhi_user_search.
    const { data, error } = await supabase
      .from("super_map")
      .select()
    console.log("error", error);
    context.response.body = data;
  })
  .get("/one", async (context) => {

    const supabase = createClient(
        // Supabase API URL - env var exported by default.
        Deno.env.get("SUPABASE_URL") ?? "",
        // Supabase API ANON KEY - env var exported by default.
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        // Create client with Auth context of the user that called the function.
        // This way your row-level-security (RLS) policies are applied.
        // { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
      );

      
    let id = context.request.url.searchParams.get("id");
    let name = context.request.url.searchParams.get("name");

    let data, error;
    
    if (id) {
        // If 'id' is present, parse it and find by 'id'
        id = parseInt(id, 10);
        if (isNaN(id)) {
            context.response.status = 400;
            context.response.body = { error: "Invalid ID format" };
            return;
        }
        ({ data, error } = await supabase
            .from("super_map")
            .select()
            .eq("id", id)
            .single());
    } else if (name) {
        // If 'name' is present, find by 'name'
        ({ data, error } = await supabase
            .from("super_map")
            .select()
            .ilike("name", `%${name}%`)
            .single());
    } else {
        // If neither 'id' nor 'name' are provided
        context.response.status = 400;
        context.response.body = { error: "No identifier provided" };
        return;
    }


    // Log any errors that occur during the database query
    console.log("error", error);
    if (error) {
        context.response.status = 404;
        context.response.body = { error: "Map not found", details: error };
    } else {
        context.response.body = data;
    }
  })
  .post("/create", async (context) => {

    const supabase = createClient(
    // Supabase API URL - env var exported by default.
    Deno.env.get("SUPABASE_URL") ?? "",
    // Supabase API ANON KEY - env var exported by default.
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    // Create client with Auth context of the user that called the function.
    // This way your row-level-security (RLS) policies are applied.
    // { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

      
    if (!context.request.hasBody) {
        context.response.status = 400;
        context.response.body = { error: "No data provided" };
        return;
      }

    let content = await context.request.body.text();
    const { name, description, map, uri, creator } = JSON.parse(content);
    
    const { data, error } = await supabase
    .from("super_map")
    .insert(
    {
        name: name,
        description: description,
        map: map,
        creator: creator,
        object_id: generateHexHash(16),
        uri: uri
    });
  
    console.log("error", error);

    context.response.body = {"result": data};
  })
  .post("/update", async (context) => {
    const supabase = createClient(
    // Supabase API URL - env var exported by default.
    Deno.env.get("SUPABASE_URL") ?? "",
    // Supabase API ANON KEY - env var exported by default.
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    // Create client with Auth context of the user that called the function.
    // This way your row-level-security (RLS) policies are applied.
    // { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    if (!context.request.hasBody) {
        context.response.status = 400;
        context.response.body = { error: "No data provided" };
        return;
    }
    
    let content = await context.request.body.text();
    const { id, map, uri} = JSON.parse(content);
    
    if (!id) {
        context.response.status = 400;
        context.response.body = { error: "Missing ID for update" };
        return;
    }
    
    const { error } = await supabase
        .from("super_map")
        .update({
            map: map,
            uri: uri
        })
        .eq("id", id);
    
    if (error) {
        console.error("Error updating data:", error);
        context.response.status = 500;
        context.response.body = { error: "Failed to update record" };
    } else {
        context.response.status = 200;
        context.response.body = { error };
    }
  });

const app = new Application();
app.use(oakCors()); // Enable CORS for All Routes
app.use(router.routes());

console.info("CORS-enabled web server listening on port 8000");

// app.use(async (ctx) => {
//     if (!ctx.request.hasBody) {
//       ctx.throw(415);
//     }
//     const reqBody = await ctx.request.body().value;
//     console.log("a=", reqBody.a);
//     ctx.response.status = 200;
//   });

await app.listen({ port: 8000 });
