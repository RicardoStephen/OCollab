(** Included so we could use the 3110 testing tools *)

(** [serialize x] returns a string representation of [x]. *)
val serialize : 'a -> string
(** [truncate x] prints about 100 characters of the
    string representation of [x] *)
val truncate : 'a -> string
