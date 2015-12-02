module Html = Dom_html

let docid = 
  let search = Dom_html.window##location##search in
  search##slice_end(4)

let set_full_doc mirror = 
  let req = XmlHttpRequest.create () in
  let f () =
    match (req##readyState, req##status) with
    | (XmlHttpRequest.DONE, 200) ->
       Js.Unsafe.meth_call mirror "setValue" (Array.make 1 (Js.Unsafe.inject (req##responseText)))
    | _ -> () in
  req##onreadystatechange <- (Js.wrap_callback f);
  req##_open(Js.string "GET",
             (Js.string ("/get_doc_text?id="))##concat(docid),
             Js._true);
  req##send(Js.null);
  ()
         
let handle_change _ =
  (* let d = Html.window##document in *)
  (* let body = d##body in *)
  (* let textinput = Html.createInput ~_type:(Js.string "text") d in *)
  (* textinput##defaultValue <- Js.string ("Document Name"); *)
  (* textinput##size <- 20; *)
  (* Dom.appendChild body textinput; *)
  (* Js._false *)
  let req = XmlHttpRequest.create () in
  req##_open(Js.string "GET",
             Js.string ("/dummy"),
             Js._true);
  req##send(Js.null);
  Js._false
  

let start _ =
  let body = Js.Unsafe.inject Html.window##document##body in
  let obj = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body) in
  set_full_doc obj;
  let _ = Js.Unsafe.meth_call obj "addEventListener" (Array.make 1 (Js.Unsafe.inject handle_change)) in
  Js._false

let _ = Html.window##onload <- Html.handler start



  (* let _ =  *)
  (*   match Js.Opt.to_option (Html.CoerceTo._object handle_change) with *)
  (*   | None ->  *)
  (*      let req = XmlHttpRequest.create () in *)
  (*      req##_open(Js.string "GET", *)
  (*                 Js.string ("/not_an_object"), *)
  (*            Js._true); *)
  (*      req##send(Js.null); *)
  (*      () *)
  (*   | Some x -> *)
  (*           let req = XmlHttpRequest.create () in *)
  (*      req##_open(Js.string "GET", *)
  (*                 Js.string ("/is_an_object"), *)
  (*            Js._true); *)
  (*      req##send(Js.null); *)
  (*      () in      *)
