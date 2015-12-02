module Html = Dom_html

let handle_change _ =
  (* let d = Html.window##document in *)
  (* let body = d##body in *)
  (* let textinput = Html.createInput ~_type:(Js.string "text") d in *)
  (* textinput##defaultValue <- Js.string ("Document Name"); *)
  (* textinput##size <- 20; *)
  (* Dom.appendChild body textinput; *)
  (* Js._false *)
  (* let req = XmlHttpRequest.create () in *)
  (* req##_open(Js.string "GET", *)
  (*            Js.string ("/dummy"), *)
  (*            Js._true); *)
  (* req##send(Js.null); *)
  (* (\* Js._false *\) *)
  let _ = Js.Unsafe.meth_call Js.Unsafe.global "alert" 
                              (Array.make 1 (Js.Unsafe.inject (Js.string "Button was clicked"))) in
  Js._false
  

let start _ =
  (* let f = Js.wrap_callback handle_change in *)
  (* Js.Unsafe.global##cb <- f; *)
  (* Js.Unsafe.global##cb##apply <- Js.wrap_callback (fun x -> handle_change x); *)  
  (* let f = Js.Unsafe.inject (Js.wrap_callback handle_change) in*)
  (*Js.Unsafe.global##cb = Js.wrap_callback handle_change;*)
  let source = jsnew EventSource.eventSource (Js.string "cb") in
  let event = Dom.Event.make "click" in
  let listener = EventSource.addEventListener source event (Dom.handler handle_change) in
  (* let f1 = Js.Unsafe.global##cb in *)
  (* let e = Js.Unsafe.inject (Js.string "change")in                *)
  (* let arr = Array.make 2 f1 in *)
  (* Array.set arr 0 e; *)
  (* let _ = Js.Unsafe.meth_call obj "addEventListener" arr in *)
  Js._false
