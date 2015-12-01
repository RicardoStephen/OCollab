exception Assert_true of string
(** [assert_true e] Returns [unit] if [e] is the boolean
    [true] and raises [Assert_true] otherwise. *)
val assert_true : bool -> unit

exception Assert_false of string
(** [assert_false e] Returns [unit] if [e] is the boolean
    [false] and raises [Assert_false] otherwise. *)
val assert_false : bool -> unit

exception Assert_greater of string
(** [assert_greater e1 e2] Returns [unit] if the comparison [e1 > e2]
    evaluates to the boolean [true] and raises [Assert_greater] otherwise. *)
val assert_greater : 'a -> 'a -> unit

exception Assert_less of string
(** [assert_less e1 e2] Opposite of [assert_greater] -- returns unit
    if the comparison [e1 < e2] evaluates to [true] and raises [Assert_less]
    otherwise. *)
val assert_less : 'a -> 'a -> unit

exception Assert_equal of string
(** [assert_equal p e1 e2] Returns [unit] if for the binary relation [p],
    [p e1 e2] evaluates to [true]. Raises [Assert_equal] otherwise. *)
val assert_equal : ('a -> 'a -> bool) -> 'a -> 'a -> unit
(** [e1 === e2] is short for [assert_equal (=) e1 e2]. *)
val (===) : 'a -> 'a -> unit

exception Almost_equal of string
(** [almost_equal e1 e2] Returns [unit] if the floating point
    numbers [e1] and [e2] are within a small, hard-coded threshold
    of one another. *)
val almost_equal : float -> float -> unit

exception Assert_not_equal of string
(** [assert_not_equal e1 e2] Opposite of [(===)]. Returns
    [unit] if [e1 === e2] evaluates to [false] and raises
    [Assert_not_equal] otherwise. *)
val assert_not_equal : 'a -> 'a -> unit

exception Assert_is of string
(** [assert_is e1 e2] Returns [unit] if the shallow/referential
    equality [e1 == e2] is [true]. Otherwise raises [Assert_is]. *)
val assert_is : 'a -> 'a -> unit

exception Assert_is_not of string
(** [assert_is_not e1 e2] Opposite of [assert_is]. Returns
    [unit] if [e1 != e2] is [true] and raises [Assert_is_not] otherwise. *)
val assert_is_not : 'a -> 'a -> unit

exception Assert_is_none of string
(** [assert_is_none e] Returns [unit] if the option [e] is the constructor
    [None]. Otherwise raises [Assert_is_none]. *)
val assert_is_none : 'a option -> unit

exception Assert_is_not_none of string
(** [assert_is_not_none e] Returns [unit] if the option [e] is not
    the constructor [None]. Otherwise raises [Assert_is_not_none]. *)
val assert_is_not_none : 'a option -> unit

exception Assert_raises of string
(** [assert_raises e_opt f x] evaluates [f x] and acts conditionally on the value of [e_opt].
    If [f x] does not raise an exception, this function raises [Assert_raises]. Otherwise,
    if [e_opt] is [None] then this function returns [unit]. Lastly if [f x] raises the
    exception [e] and [e_opt] is [Some e'], then this function returns [unit] if [e] and [e']
    are the same exception and raises [Assert_raises] otherwise. *)
val assert_raises : exn option -> ('a -> 'b) -> 'a -> unit

exception Timeout
(** [timeout i f x] executes [f x], terminating in at most [i]
    seconds. Raises [Timeout] if [f x] was killed early. *)
val timeout : int -> ('a -> 'b) -> 'a -> 'b

(*exception QCheck_result of int * string
(** [assert_qcheck gen exp] Generates a bunch of inputs to the proposition [exp]
    using the generator [gen]. The exact number is hardcoded in [assertions.ml] and
    [util.ml]. Raises [QCheck_result] with a message for harness to parse if [exp]
    fails on any inputs. *)
val assert_qcheck : 'a QCheck.Arbitrary.t -> 'a QCheck.Prop.t -> unit
*)
