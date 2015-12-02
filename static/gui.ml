module Html = Dom_html
open Patch

let docid    = Js.Unsafe.js_expr "window.doc_id"
let title    = Js.Unsafe.js_expr "window.doc_title"
let fulltext = Js.Unsafe.js_expr "window.doc_text"

let set_full_doc cm = cm##setValue(fulltext)

let cur_patch = ref empty_patch

let patch_of_change cm obj =
  let frm = Js.Unsafe.get obj (Js.string "from") in
  let too = Js.Unsafe.get obj (Js.string "to") in
  let st = truncate (Js.float_of_number (cm##indexFromPos(frm))) in
  let en = truncate (Js.float_of_number (cm##indexFromPos(too))) in
  let text = Js.to_string (obj##text##join(Js.string "\n")) in
  (* needs to attach to beforeChange so we can get the text before it's gone *)
  let dtext = Js.to_string (cm##getRange(frm, too, Js.string "\n")) in
  let del = if st = en then [] else [{op = Delete; pos = st; text = dtext}] in
  let ins = if text = "" then [] else [{op = Insert; pos = st; text = text}] in
  compose del ins

let apply_patch_cm cm p =
  let apply_edit_cm e =
    let st = cm##posFromIndex(Js.number_of_float (float_of_int e.pos)) in
    match e.op with
    | Insert ->
      let _ = cm##replaceRange(Js.string e.text, st, st) in ()
    | Delete ->
      let en = cm##posFromIndex(Js.number_of_float (float_of_int (e.pos + (String.length e.text)))) in
      let _ = cm##replaceRange(Js.string "", st, en) in ()
  in
  List.iter apply_edit_cm p


let translate_op obj =
  let x = Js.to_string (obj##origin) in
  match x with
  | "+insert" -> Add
  | "+delete" -> Del
  | _ -> failwith "Good Grief"

let update_buffer cm x =
  (* cur_patch := compose cur_patch (patch_of_change cm x); *)
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
  let cm = Js.Unsafe.meth_call Js.Unsafe.global "CodeMirror" (Array.make 1 body) in
  let _ = set_full_doc cm in
  let f = Js.Unsafe.inject handle_change in
  let e = Js.Unsafe.inject (Js.string "change") in
  let arr = Array.make 2 f in
  Array.set arr 0 e;
  let _ = Js.Unsafe.meth_call cm "on" arr in
  Js._false

let _ = Html.window##onload <- Html.handler start
