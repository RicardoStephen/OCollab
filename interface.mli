(* Reference: https://ocsigen.org/tuto/manual/application
              http://ocsigen.org/eliom/4.2/manual/server-services *)

(* Register application *)
(* main service should send gui js *)
(* addtitional services *)
(* - Send codemirror code *)
(* - handle edit actions *)
(* - handle update requests *)
(* - handles initial document fetch. Should instantiate a new document if it does not
     exist *)

(* TODO This is what an elium applicaiton or service looks like (see below). Does it have
   any place in a mli? Maybe this all should be part of the server.ml file, but inteface
   allows the server to parse json from gui, do server-side manipulations on pathches,
   and interface with the storage system? *)

module My_app =
  Eliom_registration.App (struct
                           let application_name = "graffiti"
                         end)

let main_service =
  My_app.register_service
    ~path:[""]
    ~get_params:Eliom_parameter.unit
    (fun () () ->
     Lwt.return
       (html
          (head (title (pcdata "Graffiti")) [])
          (body [h1 [pcdata "Graffiti"]]) ) )
