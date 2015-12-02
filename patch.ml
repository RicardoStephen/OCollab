type operation = Insert | Delete

type edit = {op : operation; pos : int; text : string}

type patch = edit list

type document_text = string

(* Implementation *)

let empty_patch = []

let empty_doc = ""

let compose p1 p2 = p1 @ p2

let add_edit ed p = compose p [ed]

let inverse p =
  let inverse_op op =
    match op with
    | Insert -> Delete
    | Delete -> Insert
  in
  let inverse_edit edit =
    {op = inverse_op edit.op; pos = edit.pos; text = edit.text}
  in
  let rec helper p =
    match p with
    | [] -> []
    | h::t -> compose (helper t) [inverse_edit h]
  in
  helper p

let slice s a b =
  let a = max a 0 in
  let b = min (String.length s) b in
  if b <= a then "" else String.sub s a (b - a)

let merge p1 p2 =
  let flip (a, b) = (b, a) in
  let nonempty edit = if String.length edit.text = 0 then [] else [edit] in
  let rec merge_edit e1 e2 =
    let len1 = String.length e1.text in
    let len2 = String.length e2.text in
    let end1 = e1.pos + len1 in
    let end2 = e2.pos + len2 in
    let diff = end1 - e2.pos in
    if e1.pos > e2.pos || (e1.pos = e2.pos && end1 > end2) then
      flip (merge_edit e2 e1)
    else
      match (e1.op, e2.op) with
      | (Insert, Delete) ->
        ([{e2 with pos = e2.pos + (String.length e1.text)}], [e1])
      | (Insert, Insert) ->
        ([{e2 with pos = e2.pos + (String.length e1.text)}], [e1])
      | (Delete, Delete) ->
        let a = min end1 end2 in
        let b = max e1.pos e2.pos in
        if b > a then
          ([{e2 with pos = e2.pos - len1}], [e1])
        else
          (nonempty {e2 with pos = e1.pos; text = slice e2.text (a - e2.pos) len2},
          compose
            (nonempty {e1 with text = slice e1.text 0 (b - e1.pos)})
            (nonempty {e1 with text = slice e1.text (a - e1.pos) len1}))
      | (Delete, Insert) ->
        if end1 <= e2.pos then
          ([{e2 with pos = e2.pos - len1}], [e1])
        else
          ([{e2 with pos = e1.pos}],
          compose
            (nonempty {e1 with text = slice e1.text 0 (e2.pos - e1.pos)})
            (nonempty {e1 with pos = e1.pos + len2; text = slice e1.text (e2.pos - e1.pos) len1}))
  in
  let rec go p1 p2 =
    match (p1, p2) with
    | ([], _) -> (p2, p1)
    | (_, []) -> (p2, p1)
    | (a::[], b::[]) -> merge_edit a b
    | (a::[], b::t) ->
      let (b', a')  = merge_edit a b in
      let (t', a'') = go a' t in
      (compose b' t', a'')
    | (a::t, b) ->
      let (b', a')  = go [a] b in
      let (b'', t') = go t b' in
      (b'', compose a' t')
  in
  go p1 p2

(* This might end up being slow. Two ways of making it faster would be to use a
 * rope instead of a string, or to require patches to be sorted by edit
 * position. *)
let apply_patch doc p =
  let apply_edit doc e =
    let len = String.length doc in
    let before = String.sub doc 0 e.pos in
    match e.op with
    | Insert -> before ^ e.text ^ (String.sub doc e.pos (len - e.pos))
    | Delete -> before ^ (String.sub doc (e.pos + String.length e.text) (len - e.pos - (String.length e.text)))
  in
  List.fold_left apply_edit doc p

(* Using Yojson for this *)
let rec string_of_patch p =
  (*let f = fun acc x ->
            let op_str = match x.op with Insert -> "Insert," | Delete -> "Delete," in
            op_str ^ string_of_int x.pos ^ "," ^ x.text ^ ";" ^ acc in
  List.fold_left f "" p
*)
  let rec get_json p j =
    (* Convert patch to Yojson representing edits *)
    match p with
    | h::t ->
      let to_add =
        if h.op = Insert then
          (* [Yojson.Basic.from_string "{\"op\":\"Insert\",\"pos\":0,\"text\":asdfasfasfasdf}"] *)
          Yojson.Basic.from_string ("{\"op\":\"Insert\",\"pos\":" ^ (string_of_int h.pos) ^ ",\"text\":\"" ^ h.text ^  "\"}")
        else
          (* [Yojson.Basic.from_string "{\"op\":\"Delete\",\"pos\":0,\"text\":asdfasfasfasdf}"] *)
          Yojson.Basic.from_string ("{\"op\":\"Delete\",\"pos\":" ^ (string_of_int h.pos) ^ ",\"text\":\"" ^ h.text ^  "\"}")
      in
      (get_json t (to_add::j))  (*Does this result in correct order?*)
    | [] -> (* j *) `List(j) (*Creating json list from list of json elements where each element corresponds to one edit*)
  in
  Yojson.Basic.to_string (get_json p [])

let patch_of_string p =
  let json = Yojson.Basic.from_string p in
  let lst_json = match json with
  | `List(l) -> l
  | _ -> failwith "Should be a list" in

  let f = fun acc x ->
    let record = match x with | `Assoc(v) -> v | _ -> failwith "Should be `Assoc" in
    let operation = match snd (List.nth record 0) with `String(s) -> s | _ -> failwith "" in
    let position = match snd (List.nth record 1) with `Int(i) -> i | _ -> failwith "" in
    let text = match snd (List.nth record 2) with `String(s) -> s | _ -> failwith "" in
    if operation = "Insert" then
      {op = Insert; pos = position; text = text}::acc
    else
      {op = Delete; pos = position; text = text}::acc
      in
  List.fold_left f [] lst_json
