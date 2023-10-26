--[[
  Name: AbstractDomain.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2023-09-XX
--]]

--* Dependencies *--
local ModuleManager = require("ModuleManager/ModuleManager"):newFile("StaticAnalyzer/AbstractDomain")
local Helpers = ModuleManager:loadModule("Helpers/Helpers")
local LuaState = ModuleManager:loadModule("LuaState/LuaState")

local insert = table.insert

--* AbstractDomain *--
local AbstractDomain = {}
function AbstractDomain:new(luaState)
  local AbstractDomainInstance = {}
  
  local Env = luaState.env
  local Register = luaState.register or {}
  local Upvalues = luaState.upvalues or {}
  local Constants = luaState.constants or {}
  local Protos = luaState.protos or {}
  local VarArg = luaState.vararg or {}

  local range;
  local function range(a, b, ...)
    if not a or not b then return end
    local tb = { unpack(range(...)) }
    for i = a, b do insert(tb, i) end
    return tb
  end;

  -- Constant 
  local RK;
  local function RK(tb, isRegister)
    local newTb = {}
    for _, value in ipairs(tb) do
      if not isRegister and Constants[value] then
        insert(newTb, value)
      else
        insert(newTb, value)
      end
    end

    return newTb
  end

  function InstructionFunctionalityObject.MOVE(A, B)
    return { Registers_Changed = {A}, Register_Used = {B} }
  end;
  function InstructionFunctionalityObject.LOADK(A, B)
    return { Registers_Changed = {A}, Constants_Used = {B} }
  end;
  function InstructionFunctionalityObject.LOADBOOL(A, B, C)
    if C ~= 0 then return { Registers_Changed = {A}, Jump = 1}
    else return { Registers_Changed = {A} } end
  end;
  function InstructionFunctionalityObject.LOADNIL(A, B)
    return { Registers_Changed = range(A, B) }
  end;
  function InstructionFunctionalityObject.GETUPVAL(A, B)
    return { Registers_Changed = {A}, Upvalues_Used = {B} }
  end;
  function InstructionFunctionalityObject.GETGLOBAL(A, B)
    return { Registers_Changed = {A}, Constants_Used = {B} }
  end;
  function InstructionFunctionalityObject.GETTABLE(A, B, C)
    if Constants[C] then
      return { Registers_Changed = {A}, Registers_Used = {B}, Constants_Used = {C} }
    end
    return { Registers_Changed = {A}, Registers_Used = {B, C} }
  end;
  function InstructionFunctionalityObject.SETGLOBAL(A, Bx)
    return { Registers_Used = {Bx}, Constants_Used = {A}, NoReplace = true }
  end;
  function InstructionFunctionalityObject.SETUPVAL(A, B)
    return { Upvalues_Changed = {B}, Registers_Used = {A} }
  end;
  function InstructionFunctionalityObject.SETTABLE(A, B, C)
    return { Registers_Used = {A} }
    Register[A][Constants[B] or Register[B]] = (Constants[C] or Register[C])
  end;

  -- OP_NEWTABLE [A, B, C]    R(A) := {} (size = B,C)
  -- Create a new table
  function InstructionFunctionalityObject.NEWTABLE(A, B, C)
    Register[A] = {}
  end;

  -- OP_SELF [A, B, C]    R(A+1) := R(B); R(A) := R(B)[RK(C)]
  -- Prepare an object method for calling
  function InstructionFunctionalityObject.SELF(A, B, C)
    Register[A + 1] = Register[B]
    Register[A] = Register[B][Constants[C] or Register[C]]
  end;

  -- OP_ADD [A, B, C]    R(A) := RK(B) + RK(C)
  -- Addition operator
  function InstructionFunctionalityObject.ADD(A, B, C)
    Register[A] = (Constants[B] or Register[B]) + (Constants[C] or Register[C])
  end;

  -- OP_SUB [A, B, C]    R(A) := RK(B) - RK(C)
  -- Subtraction operator
  function InstructionFunctionalityObject.SUB(A, B, C)
    Register[A] = (Constants[B] or Register[B]) - (Constants[C] or Register[C])
  end;

  -- OP_MUL [A, B, C]    R(A) := RK(B) * RK(C)
  -- Multiplication operator
  function InstructionFunctionalityObject.MUL(A, B, C)
    Register[A] = (Constants[B] or Register[B]) * (Constants[C] or Register[C])
  end;

  -- OP_DIV [A, B, C]    R(A) := RK(B) / RK(C)
  -- Division operator
  function InstructionFunctionalityObject.DIV(A, B, C)
    Register[A] = (Constants[B] or Register[B]) / (Constants[C] or Register[C])
  end;

  -- OP_MOD [A, B, C]    R(A) := RK(B) % RK(C)
  -- Modulus (remainder) operator
  function InstructionFunctionalityObject.MOD(A, B, C)
    Register[A] = (Constants[B] or Register[B]) % (Constants[C] or Register[C])
  end;

  -- OP_POW [A, B, C]    R(A) := RK(B) ^ RK(C)
  -- Exponentation operator
  function InstructionFunctionalityObject.POW(A, B, C)
    Register[A] = (Constants[B] or Register[B]) ^ (Constants[C] or Register[C])
  end;

  -- OP_UNM [A, B]    R(A) := -R(B)
  -- Unary minus
  function InstructionFunctionalityObject.UNM(A, B, C)
    Register[A] = -Register[B]
  end;

  -- OP_NOT [A, B]    R(A) := not R(B)
  -- Logical NOT operator
  function InstructionFunctionalityObject.NOT(A, B, C)
    Register[A] = not Register[B]
  end;

  -- OP_LEN [A, B]    R(A) := length of R(B)
  -- Length operator
  function InstructionFunctionalityObject.LEN(A, B, C)
    Register[A] = #Register[B]
  end;

  -- OP_CONCAT [A, B, C]    R(A) := R(B).. ... ..R(C)
  -- Concatenate a range of registers
  function InstructionFunctionalityObject.CONCAT(A, B, C)
    local stringTb = {}
    local counter = 1
    for i = B, C do
      stringTb[counter] = Register[i]
      counter = counter + 1
    end
    Register[A] = concat(stringTb)
  end;

  -- OP_JMP [sBx]    pc+=sBx
  -- Unconditional jump
  function InstructionFunctionalityObject.JMP(A)
    VM.pc = VM.pc + A
  end;

  -- OP_EQ [A, B, C]    if ((RK(B) == RK(C)) ~= A) then pc++ 
  -- Equality test, with conditional jump
  function InstructionFunctionalityObject.EQ(A, B, C)
    local RK_B = Constants[B] or Register[B]
    local RK_C = Constants[C] or Register[C]

    if (RK_B == RK_C) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_LT [A, B, C]    if ((RK(B) <  RK(C)) ~= A) then pc++
  -- Less than test, with conditional jump
  function InstructionFunctionalityObject.LT(A, B, C)
    local RK_B = Constants[B] or Register[B]
    local RK_C = Constants[C] or Register[C]

    if ( RK_B < RK_C ) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_LE [A, B, C]    if ((RK(B) <= RK(C)) ~= A) then pc++
  -- Less than or equal to test, with conditional jump
  function InstructionFunctionalityObject.LE(A, B, C)
    local RK_B = Constants[B] or Register[B]
    local RK_C = Constants[C] or Register[C]

    if ( RK_B <= RK_C ) ~= (A == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_TEST [A, C]    if not (R(A) <=> C) then pc++
  -- Boolean test, with conditional jump
  function InstructionFunctionalityObject.TEST(A, B, C)
    local B = C or B -- For future compabillity.
    if (not Register[A]) == (B == 1) then
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_TESTSET [A, B, C]    if (R(B) <=> C) then R(A) := R(B) else pc++
  -- Boolean test, with conditional jump and assignment
  function InstructionFunctionalityObject.TESTSET(A, B, C)
    if (not not Register[B]) == (C == 1) then
      Register[A] = Register[B]
    else
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_CALL [A, B, C]    R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
  -- Call a closure
  function InstructionFunctionalityObject.CALL(A, B, C)
    local Arguments = {}

    local _Index = 1
    for i = A + 1, A + B - 1 do
      Arguments[_Index] = Register[i]
      _Index = _Index + 1
    end
    local Results = {Register[A](unpack(Arguments))}
    
    _Index = 1
    for i = A, A + C - 2 do
      Register[i] = Results[_Index]
      _Index = _Index + 1
    end
  end;

  -- OP_TAILCALL [A, B, C]    return R(A)(R(A+1), ... ,R(A+B-1))
  -- Perform a tail call
  function InstructionFunctionalityObject.TAILCALL(A, B, C)
    local Arguments = {}
    local _Index = 1
    for i = A + 1, A + B - 1 do
      Arguments[_Index] = Register[i]
      _Index = _Index + 1
    end

    returnFromClosure({Register[A](unpack(Arguments))})
  end;

  -- OP_RETURN [A, B]    return R(A), ... ,R(A+B-2)
  -- Return from function call
  function InstructionFunctionalityObject.RETURN(A, B)
    local Table1 = {}
    local _Index = 1
    for i = A, A + B - 2 do
      Table1[_Index] = Register[i]
      _Index = _Index + 1
    end

    returnFromClosure(Table1)
  end;

  -- OP_FORLOOP [A, sBx]   R(A)+=R(A+2);
  --                       if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
  -- Iterate a numeric for loop 
  function InstructionFunctionalityObject.FORLOOP(A, B)

    local _ = Register[A] + Register[A + 2]
    if _ <= Register[A + 1] then
      VM.pc = VM.pc + B
      Register[A + 3] = _
    end
    Register[A] = _
  end;

  -- OP_FORPREP [A, sBx]    R(A)-=R(A+2); pc+=sBx
  -- Initialization for a numeric for loop
  function InstructionFunctionalityObject.FORPREP(A, B)
    Register[A] = Register[A] - Register[A + 2]
    VM.pc = VM.pc + B
  end;

  -- OP_TFORLOOP [A, C]    R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
  --                       if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
  -- Iterate a generic for loop
  function InstructionFunctionalityObject.TFORLOOP(A, B, C)
    local C = C or B
    local Table1 = {Register[A](Register[A + 1], Register[A + 2])}
    local _Index = 1
    for i = A + 3, A + 2 + C do
      Register[i] = Table1[_Index]
      _Index = _Index + 1
    end
    if Register[A + 3] ~= nil then
      Register[A + 2] = Register[A + 3]
    else
      VM.pc = VM.pc + 1
    end
  end;

  -- OP_SETLIST [A, B, C]    R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
  -- Set a range of array elements for a table
  function InstructionFunctionalityObject.SETLIST(A, B, C)
    local Table = Register[A]
    local _Index = 1
    -- I changed here "A + B" to "A + B + 1",
    -- I need to check it later.
    for i = A + 1, A + B + 1, C do
      Table[_Index] = Register[i]
      _Index = _Index + 1
    end
  end;

  -- OP_CLOSE [A]
  -- close( R(0), ..., R(A) )
  -- close all variables in the stack up to (>=) R(A)
  function InstructionFunctionalityObject.CLOSE(A)
    for i = 0, A do
      Register[i] = nil
    end
  end;

  -- OP_CLOSURE [A, Bx]
  -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
  -- Create a closure of a function prototype
  function InstructionFunctionalityObject.CLOSURE(A, B)
    -- Protos are Lua states
    local proto = Protos[B]
    Register[A] = function(...)
      return VirtualMachine:new(proto):handler(...)
    end
  end;

  -- OP_VARARG [A, B]
  -- R(A), R(A+1), ..., R(A+B-1) = vararg
  -- assign vararg function arguments to registers
  function InstructionFunctionalityObject.VARARG(A, B)
    local VarArgIndex = 1
    for i = A, A + B - 1 do
      Register[i] = VarArg[VarArgIndex]
      VarArgIndex = VarArgIndex + 1
    end
  end;
  return AbstractDomainInstance
end

return AbstractDomain