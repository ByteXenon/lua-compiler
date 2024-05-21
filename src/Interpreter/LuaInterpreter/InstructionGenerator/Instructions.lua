--[[
  Name: Instructions.lua
  Author: ByteXenon [Luna Gilbert]
  Date: 2024-05-08
--]]

--* Import library functions *--
local insert = table.insert

--* Instructions class *--
local Instructions = {}

-- Add an instruction to the luaState.instructions table
function Instructions:addInstruction(opName, a, b, c)
  local instructions = self.currentProto.instructions
  local instruction = { opName, a, b, c }

  insert(instructions, instruction)
  return #instructions
end

-- Add a list of instructions to the luaState.instructions table
function Instructions:addInstructions(instructionTable)
  local instructions = self.currentProto.instructions
  for _, instruction in ipairs(instructionTable) do
    insert(instructions, instruction)
  end
end

-- Change an instruction in the luaState.instructions table
function Instructions:changeInstruction(instructionIndex, opName, a, b, c)
  local oldInstruction = self.currentProto.instructions[instructionIndex]
  local newInstruction = {opName, a, b, c}

  for i = 1, 4 do
    newInstruction[i] = newInstruction[i] or oldInstruction[i]
  end

  self.currentProto.instructions[instructionIndex] = newInstruction
end

-- Change the OPName of an instruction in the luaState.instructions table
function Instructions:changeInstructionOPName(instructionIndex, OPName)
  local instruction = self.currentProto.instructions[instructionIndex]
  instruction[1] = OPName
end

-- Change the A value of an instruction in the luaState.instructions table
function Instructions:changeInstructionA(instructionIndex, A)
  local instruction = self.currentProto.instructions[instructionIndex]
  instruction[2] = A
end

-- Change the B value of an instruction in the luaState.instructions table
function Instructions:changeInstructionB(instructionIndex, B)
  local instruction = self.currentProto.instructions[instructionIndex]
  instruction[3] = B
end

-- Change the C value of an instruction in the luaState.instructions table
function Instructions:changeInstructionC(instructionIndex, C)
  local instruction = self.currentProto.instructions[instructionIndex]
  instruction[4] = C
end

-- Get instructions within a range, it will be used to get instructions that
-- were generated by individual expression/statement functions.
function Instructions:getInstructionsFromRange(startIndex, endIndex)
  local instructions = self.currentProto.instructions
  local instructionTable = {}
  for index = startIndex, endIndex do
    insert(instructionTable, instructions[index])
  end

  return instructionTable
end

-- Remove instructions within a range and return them, it will be used to remove instructions that
-- were generated by individual expression/statement functions.
function Instructions:removeInstructionsFromRange(startIndex, endIndex)
  local instructions = self.currentProto.instructions
  local instructionTable = {}

  for index = startIndex, endIndex do
    insert(instructionTable, instructions[index])
    instructions[index] = nil
  end
  return instructionTable
end

return Instructions