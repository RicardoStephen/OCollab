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
      let _ = cm##replaceRange
        (Js.string e.text, st, st, Js.string "self") in ()
    | Delete ->
      let en = cm##posFromIndex
        (jsnum_of_int (e.pos + (String.length e.text))) in
      let _ = cm##replaceRange
        (Js.string "", st, en, Js.string "self") in ()
  in
  cm##operation(Js.Unsafe.inject (fun _ -> List.iter apply_edit_cm p))

let show_cursors_cm cm cursors =
  let open Yojson.Basic in
  let last_line = Js.to_string (Js.string (cm##lineCount())) in
  List.iter (fun c -> (
    match Util.to_list c with
    | jhue::jcsl::jcsc::jcel::jcec::[] ->
      let hue = Util.to_int jhue in
      let csl = Util.to_int jcsl in
      let csc = Util.to_int jcsc in
      let cel = Util.to_int jcel in
      let cec = Util.to_int jcec in
      let color = "hsl(" ^ (string_of_int hue) ^ ", 100%, 50%)" in
      cm##markText(
        Json.unsafe_input (Js.string ("{\"line\":0, \"ch\":0}")),
        Json.unsafe_input (Js.string ("{\"line\":"
          ^ last_line ^ ", \"ch\":0}")),
        Json.unsafe_input (Js.string
          ("{\"css\":\"background-color: transparent;" ^
          "border: none; margin: 0px\"}")));
      if csl = cel && csc = cec then
        (* Show a single cursor line *)
        if csc = 0 then
          (* Special case: cursor is first, line on left *)
          cm##markText(
            Json.unsafe_input (Js.string
              ("{\"line\":" ^ (string_of_int csl) ^
              ", \"ch\":" ^ (string_of_int csc) ^ "}")),
            Json.unsafe_input (Js.string
              ("{\"line\":" ^ (string_of_int cel) ^
              ", \"ch\":" ^ (string_of_int (cec + 1)) ^ "}")),
            Json.unsafe_input (Js.string
              ("{\"css\":\"border-left: 2px solid " ^ color ^ ";" ^
              "margin-left: -2px\"}")))
        else
          (* Common case: line on right *)
          cm##markText(
            Json.unsafe_input (Js.string
              ("{\"line\":" ^ (string_of_int csl) ^
              ", \"ch\":" ^ (string_of_int (csc - 1)) ^ "}")),
            Json.unsafe_input (Js.string
              ("{\"line\":" ^ (string_of_int cel) ^
              ", \"ch\":" ^ (string_of_int cec) ^ "}")),
            Json.unsafe_input (Js.string
              ("{\"css\":\"border-right: 2px solid " ^ color ^ ";" ^
              "margin-right: -2px\"}")))
      else
        (* Mark an entire range *)
        cm##markText(
          Json.unsafe_input (Js.string
            ("{\"line\":" ^ (string_of_int csl) ^
            ", \"ch\":" ^ (string_of_int csc) ^ "}")),
          Json.unsafe_input (Js.string
            ("{\"line\":" ^ (string_of_int cel) ^
            ", \"ch\":" ^ (string_of_int cec) ^ "}")),
          Json.unsafe_input (Js.string
            ("{\"css\":\"background-color: " ^ color ^ "\"}")))
    | _ -> ())) cursors

let rec send_to_server cm patch () : unit =
  let req = XmlHttpRequest.create () in
  let patch_string = Js.string (string_of_patch patch) in
  let cursor_from = cm##getCursor(Js.string "from") in
  let cursor_to = cm##getCursor(Js.string "to") in
  let args =
    ((Js.string "sid=")##concat(sid))
    ##concat((Js.string "&patch=")
      ##concat(Js.encodeURIComponent patch_string))
    ##concat((Js.string "&csl=")##concat(Js.string cursor_from##line))
    ##concat((Js.string "&csc=")##concat(Js.string cursor_from##ch))
    ##concat((Js.string "&cel=")##concat(Js.string cursor_to##line))
    ##concat((Js.string "&cec=")##concat(Js.string cursor_to##ch))
  in
  let handler _ =
    match (req##readyState, req##status) with
    | (XmlHttpRequest.DONE, 200) ->
      let open Yojson.Basic in
      let resp = from_string (Js.to_string req##responseText) in
      let p = patch_of_string (Util.to_string (Util.member "patch" resp)) in
      let q = !cur_patch in
      cur_patch := empty_patch;
      let (q', p') = merge p q in

      let cursors = Util.to_list (Util.member "cursors" resp) in
      apply_patch_cm cm p';
      show_cursors_cm cm cursors;
      ignore (Dom_html.window##setTimeout(
        Js.wrap_callback (send_to_server cm q'), 500.0));
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
  let _ = cm##setValue(fulltext) in
  let _ = cm##on(Js.string "beforeChange", Js.Unsafe.inject handle_change) in
  send_to_server cm empty_patch ();
  Js._false

let _ = Html.window##onload <- Html.handler start
