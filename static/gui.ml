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

type operation =  Add | Del

let buffer = ref (Add, "")

let translate_op obj =
  let x = Js.to_string (obj##origin) in
  match x with
  | "+insert" -> Add
  | "+delete" -> Del
  | _ -> failwith "Good Grief"

let update_buffer _ x =
  match ((translate_op x) = (fst !buffer)) with
  | true -> buffer := (fst !buffer, (snd !buffer)^(Array.get (Js.to_array (x##text)) 0));
            Js._false
  | false ->
     let req = XmlHttpRequest.create () in
     req##_open(Js.string "GET",
                Js.string (snd (!buffer)),
                Js._true);
     req##send(Js.null);
     buffer := (translate_op x, Array.get (Js.to_array (x##text)) 0);
     Js._false

(* Useful for testing *)         
let handle_change _ x =
  let _ = Js.Unsafe.meth_call Js.Unsafe.global##console "log" (Array.make 1 x) in
  Js._false
  

let start _ =
  let body = Js.Unsafe.inject Html.window##document##body in
  let obj = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body) in
  set_full_doc obj;
  (* let f = Js.wrap_callback handle_change in *)
  (* Js.Unsafe.global##cb <- f; *)
  (* Js.Unsafe.global##cb##apply <- Js.wrap_callback (fun x -> handle_change x); *)  
  (* let f = Js.Unsafe.inject (Js.wrap_callback handle_change) in*)
  (*Js.Unsafe.global##cb = Js.wrap_callback handle_change;*)
  (* let source = jsnew EventSource.eventSource (Js.string "cb") in *)
  (* let event = Dom.Event.make "change" in *)
  (* let listener = EventSource.addEventListener source obj (Dom.handler handle_change) in *)
  (* let f1 = Js.Unsafe.global##cb in *)
  (* let e = Js.Unsafe.inject (Js.string "change")in                *)
  (* let arr = Array.make 2 f1 in *)
  (* Array.set arr 0 e; *)
  (* let _ = Js.Unsafe.meth_call obj "addEventListener" arr in *)  
  (* let f = Js.Unsafe.inject update_buffer in *)
  let f = Js.Unsafe.inject handle_change in
  let e = Js.Unsafe.inject (Js.string "change") in
  let arr = Array.make 2 f in
  Array.set arr 0 e;
  let _ = Js.Unsafe.meth_call obj "on" arr in
  Js._false

let _ = Html.window##onload <- Html.handler start
