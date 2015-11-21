
.PHONY: all


all: test run
	@echo "Nothing here"

compile:
	@echo "Compile"
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax \-syntax camlp4o -linkpkg -o gui_test.byte gui_test.ml
	js_of_ocaml gui_test.byte

test: compile
	@echo "Test"

run: compile
	@echo "Run"

clean:
	rm -r _build
	rm -r _cs3110

install:
	opam install -y yojson
	opam install -y js_of_ocaml
	opam depext dbm.1.0
	opam install -y eliom
	sudo apt-get install -y redis-server
	opam install -y redis

