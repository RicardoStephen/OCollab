module Html = Dom_html
open Patch

let docid    = Js.Unsafe.js_expr "window.doc_id"
let title    = Js.Unsafe.js_expr "window.doc_title"
let fulltext = Js.Unsafe.js_expr "window.doc_text"
let sid      = Js.Unsafe.js_expr "window.sid"

let cur_patch = ref empty_patch

let jsnum_of_int n = Js.number_of_float (float_of_int n)

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
    let st = cm##posFromIndex(jsnum_of_int e.pos) in
    match e.op with
    | Insert ->
      let _ = cm##replaceRange(Js.string e.text, st, st, Js.string "self") in ()
    | Delete ->
      let en = cm##posFromIndex(jsnum_of_int (e.pos + (String.length e.text))) in
      let _ = cm##replaceRange(Js.string "", st, en, Js.string "self") in ()
  in
  cm##operation(Js.Unsafe.inject (fun _ -> List.iter apply_edit_cm p))

let rec send_to_server cm patch () : unit =
  let req = XmlHttpRequest.create () in
  let patch_string = Js.string (string_of_patch patch) in
  let args =
    ((Js.string "sid=")##concat(sid))##concat(
    (Js.string "&patch=")##concat(Js.encodeURIComponent patch_string)) in
  let handler _ =
    match (req##readyState, req##status) with
    | (XmlHttpRequest.DONE, 200) ->
      let p = patch_of_string (Js.to_string req##responseText) in
      let q = !cur_patch in
      cur_patch := empty_patch;
      let (q', p') = merge p q in
      apply_patch_cm cm p';
      Dom_html.window##setTimeout(Js.wrap_callback (send_to_server cm q'), 500.0);
      ()
    | _ -> ()
  in
  req##onreadystatechange <- Js.wrap_callback handler;
  req##_open(Js.string "POST", Js.string "/exchange", Js._true);
  req##setRequestHeader(
    Js.string "Content-type",
    Js.string "application/x-www-form-urlencoded");
  req##send(Js.some args);
  ()

let handle_change cm x =
  if Js.to_string (Js.Unsafe.get x "origin") <> "self" then
    cur_patch := compose !cur_patch (patch_of_change cm x)
  else ();
  Js._false

let start _ =
  let cm = Js.Unsafe.js_expr "CodeMirror(document.body)" in
  cm##setValue(fulltext);
  cm##on(Js.string "beforeChange", Js.Unsafe.inject handle_change);
  send_to_server cm empty_patch ();
  Js._false

let _ = Html.window##onload <- Html.handler start
