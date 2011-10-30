(*
Modeling Kernel Language (MKL) toolchain
Copyright (C) 2010-2011 David Broman
MKL toolchain is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

MKL toolchain is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with MKL toolchain.  If not, see <http://www.gnu.org/licenses/>.
*)

open Evalast
open Ustring.Op
open Debugprint 

exception UnsupportedCode 

type bytecode =
  | ConstBool     (* param1 = boolvalue as int *)
  | ConstInt      (* param1 = intvalue *)
  | ConstReal     (* param1 = int index value to float list *)
  | ConstString   
  | ArgIndex    (* param1 = pointer to argvalue. 0=last argument *)



let coding c = 
  match c with 
    | ConstBool           ->  1
    | ConstInt            ->  2
    | ConstReal           ->  3
    | ConstString         ->  4
    | ArgIndex            ->  10

let prim2code p = 
  match p with
    | Ast.PrimIntMod         -> 101 
    | Ast.PrimIntAdd         -> 102
    | Ast.PrimIntSub         -> 103
    | Ast.PrimIntMul         -> 104
    | Ast.PrimIntDiv         -> 105
    | Ast.PrimIntLess        -> 106
    | Ast.PrimIntLessEqual   -> 107
    | Ast.PrimIntGreat       -> 108
    | Ast.PrimIntGreatEqual  -> 109
    | Ast.PrimIntEqual       -> 110
    | Ast.PrimIntNotEqual    -> 111
    | Ast.PrimIntNeg         -> 112
    | Ast.PrimRealAdd        -> 113
    | Ast.PrimRealSub        -> 114
    | Ast.PrimRealMul        -> 115
    | Ast.PrimRealDiv        -> 116
    | Ast.PrimRealLess       -> 117
    | Ast.PrimRealLessEqual  -> 118
    | Ast.PrimRealGreat      -> 119
    | Ast.PrimRealGreatEqual -> 120
    | Ast.PrimRealEqual      -> 121
    | Ast.PrimRealNotEqual   -> 122
    | Ast.PrimRealNeg        -> 123
    | Ast.PrimBoolAnd        -> 124
    | Ast.PrimBoolOr         -> 125
    | Ast.PrimBoolNot        -> 126
    | Ast.PrimPrint          -> 127
    | Ast.PrimBool2String    -> 128
    | Ast.PrimInt2String     -> 129
    | Ast.PrimReal2String    -> 130
    | Ast.PrimInt2Real       -> 131
    | Ast.PrimReal2Int       -> 132
    | Ast.PrimString2Bool    -> 133
    | Ast.PrimString2Int     -> 134
    | Ast.PrimString2Real    -> 135
    | Ast.PrimIsBoolString   -> 136
    | Ast.PrimIsRealString   -> 137
    | Ast.PrimIsIntString    -> 138
    | Ast.PrimSin            -> 139
    | Ast.PrimCos            -> 140
    | Ast.PrimTan            -> 141
    | Ast.PrimASin           -> 142
    | Ast.PrimACos           -> 143
    | Ast.PrimATan           -> 144
    | Ast.PrimSinh           -> 145
    | Ast.PrimCosh           -> 146
    | Ast.PrimTanh           -> 147
    | Ast.PrimCeil           -> 148
    | Ast.PrimFloor          -> 149
    | Ast.PrimLog            -> 150
    | Ast.PrimLog10          -> 151
    | Ast.PrimSqrt           -> 152
    | Ast.PrimExp            -> 153
    | Ast.PrimExponentiation -> 154
    | Ast.PrimStringConcat   -> 155
    | Ast.PrimStringStrlen   -> 156
    | Ast.PrimStringSubstr   -> 157


let prims = [
  Ast.PrimIntMod;
  Ast.PrimIntAdd;
  Ast.PrimIntSub;
  Ast.PrimIntMul;
  Ast.PrimIntDiv;
  Ast.PrimIntLess;
  Ast.PrimIntLessEqual;
  Ast.PrimIntGreat;
  Ast.PrimIntGreatEqual;
  Ast.PrimIntEqual;
  Ast.PrimIntNotEqual;
  Ast.PrimIntNeg;
  Ast.PrimRealAdd;
  Ast.PrimRealSub;
  Ast.PrimRealMul;
  Ast.PrimRealDiv;
  Ast.PrimRealLess;
  Ast.PrimRealLessEqual;
  Ast.PrimRealGreat;
  Ast.PrimRealGreatEqual;
  Ast.PrimRealEqual;
  Ast.PrimRealNotEqual;
  Ast.PrimRealNeg;
  Ast.PrimBoolAnd;
  Ast.PrimBoolOr;
  Ast.PrimBoolNot;
  Ast.PrimPrint;
  Ast.PrimBool2String;
  Ast.PrimInt2String;
  Ast.PrimReal2String;
  Ast.PrimInt2Real;
  Ast.PrimReal2Int;
  Ast.PrimString2Bool;
  Ast.PrimString2Int;
  Ast.PrimString2Real;
  Ast.PrimIsBoolString;
  Ast.PrimIsRealString;
  Ast.PrimIsIntString;
  Ast.PrimSin;
  Ast.PrimCos;
  Ast.PrimTan;
  Ast.PrimASin;
  Ast.PrimACos;
  Ast.PrimATan;
  Ast.PrimSinh;
  Ast.PrimCosh;
  Ast.PrimTanh;
  Ast.PrimCeil;
  Ast.PrimFloor;
  Ast.PrimLog;
  Ast.PrimLog10;
  Ast.PrimSqrt;
  Ast.PrimExp;
  Ast.PrimExponentiation;
  Ast.PrimStringConcat;
  Ast.PrimStringStrlen;
  Ast.PrimStringSubstr]
        
let (mapc2p : (int,Ast.primitive) Hashtbl.t) = Hashtbl.create 256 
  
let addPrims = List.iter (fun x -> Hashtbl.add mapc2p (prim2code x) x) prims
  
let isPrim c p = 
  try 
    let p1 = Hashtbl.find mapc2p c in
    p = p1
  with Not_found -> false

let code2prim c = Hashtbl.find mapc2p c  

let generate id tm = 
  let rec gen tm aCode aConst argc = 
    match tm with
      | TmClos(t,e,id) -> gen t aCode aConst (argc+1)
      | TmLam(t) -> gen t aCode aConst (argc+1)
      | TmApp(TmConst(Ast.ConstPrim(primop,[])),t1,_) ->
          let (aCode1,aConst1,argc1) = gen t1 aCode aConst argc in
          ((prim2code primop)::aCode1,aConst1,argc1)
      | TmApp(TmConst(Ast.ConstPrim(primop,[arg1])),t2,_) ->
          let t1 = TmConst(arg1) in
          let (aCode1,aConst1,argc1) = gen t1 aCode aConst argc in
          let (aCode2,aConst2,argc2) = gen t2 aCode1 aConst1 argc1 in
          ((prim2code primop)::aCode2,aConst2,argc2)
      | TmApp(TmApp(TmConst(Ast.ConstPrim(primop,[])),t1,_),t2,_) ->
          let (aCode1,aConst1,argc1) = gen t1 aCode aConst argc in
          let (aCode2,aConst2,argc2) = gen t2 aCode1 aConst1 argc1 in
          ((prim2code primop)::aCode2,aConst2,argc2)
      | TmConst(Ast.ConstReal(realconst)) -> 
          let cId = (List.length aConst) in
          (cId::(coding ConstReal)::aCode,realconst::aConst,argc)
      | TmVar(idx) -> (idx::(coding ArgIndex)::aCode,aConst,argc)
      | _ ->
          let _ = uprint_endline (Debugprint.pprint tm) in
          raise UnsupportedCode 
  in
    try
      let (aCode,aConst,argc) = gen tm [] [] 0 in
       TmByteCode((List.rev aCode,List.rev aConst,argc),ref 0,Symtbl.empty,[]) 
    with UnsupportedCode -> tm
          


let run bcode args = 
  let (code,rconsts,argc) = bcode in
  let rec rr code stack =
    let _ = print_endline "******" in
    match (code,stack) with
      | (c::i::cs,_) when c == (coding ConstReal) -> 
          let realval = List.nth rconsts i in
          rr cs (realval::stack)
      | (c::i::cs,_) when c == (coding ArgIndex) ->
          (match List.nth args i with
             | TmConst(Ast.ConstReal(x)) -> rr cs (x::stack)
             | _ -> failwith "invalid argument")
      | (c::cs,s1::s2::ss) when isPrim c Ast.PrimRealAdd -> rr cs ((s1+.s2)::ss)
      | (c::cs,s1::s2::ss) when isPrim c Ast.PrimRealSub -> rr cs ((s1-.s2)::ss)
      | (c::cs,s1::s2::ss) when isPrim c Ast.PrimRealMul -> rr cs ((s1*.s2)::ss)
      | (c::cs,s1::s2::ss) when isPrim c Ast.PrimRealDiv -> rr cs ((s1/.s2)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimSin   -> rr cs ((sin s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimCos   -> rr cs ((cos s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimTan   -> rr cs ((tan s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimASin  -> rr cs ((asin s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimACos  -> rr cs ((acos s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimATan  -> rr cs ((atan s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimLog   -> rr cs ((log s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimLog10 -> rr cs ((log10 s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimSqrt  -> rr cs ((sqrt s1)::ss)
      | (c::cs,s1::ss) when isPrim c Ast.PrimExp   -> rr cs ((exp s1)::ss)
      | (c::cs,s1::s2::ss) when isPrim c Ast.PrimExponentiation
          -> rr cs ((s1 ** s2)::ss)
      | ([], [x]) -> TmConst(Ast.ConstReal(x)) 
      | _ -> failwith "unknown byte code"
  in
    rr code [] 










