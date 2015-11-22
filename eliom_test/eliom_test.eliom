open Eliom_content.Html5.D
open Eliom_service
open Lwt

module Eliom_test_app =
  Eliom_registration.App (
    struct
      let application_name = "eliom_test"
    end)

let page =
  (html ( head (title (pcdata "Eliom Test"))
               [css_link ~uri:(make_uri  ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.css"]) ();
                js_script ~uri:(make_uri ~service:(static_dir ()) ["codemirror-5.8";"lib";"codemirror.js"]) ();
                js_script ~uri:(make_uri ~service:(static_dir ()) ["gui_js.js"]) ()]
        )
        (body [h1 [pcdata "Eliom Test"]]))

let main_service =
  Eliom_test_app.register_service ~path:[""] ~get_params:Eliom_parameter.unit
                                  (fun () () ->
                                   return page)
