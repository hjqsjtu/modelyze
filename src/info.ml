(*
Modelyze toolchain
Copyright (C) 2010-2012 David Broman

Modelyze toolchain is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Modelyze toolchain is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Modelyze toolchain.  If not, see <http://www.gnu.org/licenses/>.
*)

open Ustring.Op
open Utils

type row = int
type col = int
type filename = ustring
type info = 
  | Info of filename * row * col * row * col  
  | NoInfo

(** Create a new info, taking left and right part *)
let mkinfo fi1 fi2 =  
  match (fi1,fi2) with
    | (Info(fn,r1,c1,_,_), Info(_,_,_,r2,c2)) -> Info(fn,r1,c1,r2,c2)
    | (Info(fn,r1,c1,r2,c2), NoInfo) -> Info(fn,r1,c1,r2,c2)
    | (NoInfo, Info(fn,r1,c1,r2,c2)) -> Info(fn,r1,c1,r2,c2)
    | (_,_) -> NoInfo

let mk_right_info fi = 
    match fi with
      | Info(f,_,_,r,c) -> Info(f,r,c,r,c)
      | NoInfo -> NoInfo

let mk_left_info fi = 
    match fi with
      | Info(f,r,c,_,_) -> Info(f,r,c,r,c)
      | NoInfo -> NoInfo

let mkinfo_lst fi_ls = 
  let rec first_fi ls =
    match ls with
      | [] -> NoInfo 
      | NoInfo::ls -> first_fi ls
      | fi::ls -> fi
  in
    mkinfo (first_fi fi_ls) (first_fi (List.rev fi_ls))

let get_filename fi =
  match fi with
    | Info(name,_,_,_,_) -> 
        name |> Ustring.to_latin1 |> String.lowercase_ascii |> us
    | NoInfo -> us""

let info2str fi = 
    match fi with
      | Info(name,r1,c1,r2,c2) ->
          us"\"" ^. name ^. us"\" " ^.
	  (ustring_of_int r1) ^. us":" ^.
	  (ustring_of_int c1) ^. us"-" ^.
	  (ustring_of_int r2) ^. us":" ^.
	  (ustring_of_int c2)
      | NoInfo -> us"NoInfo"


