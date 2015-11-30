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

let merge p1 p2 =
  let flip (a, b) = (b, a) in
  let merge_edit e1 e2 =
    if e1.pos > e2.pos then flip (merge_edit e2 e1) else
    let len1 = String.length e1.text in
    let len2 = String.length e2.text in
    let end1 = e1.pos + len in
    let diff = end1 - e2.pos in
    match (e1.op, e2.op) with
    | (Insert, Insert) -> ({e2 with pos = e2.pos + (String.length e1.text)}, e1)
    | (Insert, Delete) -> ({e2 with pos = e2.pos + (String.length e1.text)}, e1)
    | (Delete, Delete) ->
      if end1 <= e2.pos then
        ({e2 with pos = e2.pos - len1}, e1)
      else
        ({e2 with pos = e2.pos - len1; text = String.sub e2.text diff (len2 - diff)},
        {e1 with text = String.sub e1.text 0 (len1 - diff)})
    | (Delete, Insert) ->
      if end1 <= e2.pos then
          ([{e2 with pos = e2.pos - len1}], [e1[)
      else
        ([{e2 with pos = e2.pos - diff}],
        [{e1 with text = String.sub e1.text 0 (len1 - diff)}; {e1 with pos = e1.pos + len1 - diff + len2; text = String.sub e1.text (len1 - diff) diff}])
  in
  let rec go p1 p2 = 
    match (p1, p2) with
    | ([], _) -> (p2, [])
    | (_, []) -> ([], p1)
    | (a::[], b::[]) -> merge_edit a b
    | (a::[], b::t) ->
      let (b', a')  = merge_edit a b in
      let (t', a'') = go a' t in
      (compose b' t', a'')
    | (a::t, b) ->
      let (b', a')  = go [a] b in
      let (b'', t') = go a' t in
      (compose b'', compose a' t')
    | (_, _) -> flip (go p2 p1)

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

let string_of_patch p = failwith "unimplemented"

let patch_of_string p = failwith "unimplemented"
