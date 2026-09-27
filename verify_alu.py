import os
import random
import subprocess

DATA_WIDTH = 32
MASK = (1 << DATA_WIDTH) - 1
SIGN_BIT = 1 << (DATA_WIDTH - 1)

ALU_OPS = {
    0x0: "ADD",
    0x1: "SUB",
    0x2: "AND",
    0x3: "OR",
    0x4: "XOR",
    0x5: "SLT",
    0x6: "SLTU",
    0x7: "SLL",
    0x8: "SRL",
    0x9: "SRA",
}


def to_signed(val):
  return val - (1 << DATA_WIDTH) if (val & SIGN_BIT) else val


def golden_alu_model(a, b, ctrl):
  shamt = b & 0x1F  # 5 bits
  carry = 0
  overflow = 0

  if ctrl == 0x0:  # ADD
    raw = a + b
    res = raw & MASK
    carry = 1 if (raw > MASK) else 0
    a_s, b_s, r_s = bool(a & SIGN_BIT), bool(b & SIGN_BIT), bool(res & SIGN_BIT)
    overflow = 1 if (a_s == b_s and r_s != a_s) else 0
  elif ctrl == 0x1:  # SUB
    raw = a - b
    res = raw & MASK
    carry = 1 if (a >= b) else 0  # Inverted borrow
    a_s, b_s, r_s = bool(a & SIGN_BIT), bool(b & SIGN_BIT), bool(res & SIGN_BIT)
    overflow = 1 if (a_s != b_s and r_s != a_s) else 0
  elif ctrl == 0x2:  # AND
    res = (a & b) & MASK
  elif ctrl == 0x3:  # OR
    res = (a | b) & MASK
  elif ctrl == 0x4:  # XOR
    res = (a ^ b) & MASK
  elif ctrl == 0x5:  # SLT (Signed)
    res = 1 if to_signed(a) < to_signed(b) else 0
  elif ctrl == 0x6:  # SLTU (Unsigned)
    res = 1 if a < b else 0
  elif ctrl == 0x7:  # SLL
    res = (a << shamt) & MASK
  elif ctrl == 0x8:  # SRL
    res = (a >> shamt) & MASK
  elif ctrl == 0x9:  # SRA
    s_a = to_signed(a)
    res = (s_a >> shamt) & MASK
  else:
    res = 0

  zero = 1 if res == 0 else 0
  negative = 1 if (res & SIGN_BIT) else 0

  return f"{res:08x} {zero} {carry} {overflow} {negative}"


def main():
  print("--> Generating Test Vectors (Corner Cases + Random)...")
  vectors = []

  # Corner cases
  corner_vals = [0x0, 0x1, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF]
  for op in ALU_OPS.keys():
    for val_a in corner_vals:
      for val_b in corner_vals:
        vectors.append((val_a, val_b, op))

  # Add 200 random vectors
  for _ in range(200):
    vectors.append((
        random.randint(0, MASK),
        random.randint(0, MASK),
        random.choice(list(ALU_OPS.keys())),
    ))

  # Write input vectors
  with open("test_vectors.txt", "w") as f:
    for a, b, op in vectors:
      f.write(f"{a:08x} {b:08x} {op:x}\n")

  # Run Icarus Verilog Simulation
  print("--> Compiling Verilog RTL & Testbench...")
  cmd_compile = ["iverilog", "-o", "alu_sim", "riscv_alu.v", "tb_riscv_alu.v"]
  subprocess.run(cmd_compile, check=True)

  print("--> Running Simulation via vvp...")
  subprocess.run(["vvp", "alu_sim"], check=True)

  # Validate results against Python Golden Model
  print("--> Comparing Hardware Output with Python Golden Model...")
  with open("results.txt", "r") as f:
    actual_results = [line.strip() for line in f if line.strip()]

  all_passed = True
  for idx, (a, b, op) in enumerate(vectors):
    expected = golden_alu_model(a, b, op)
    actual = actual_results[idx]
    if actual != expected:
      print(f"[FAIL] Test #{idx} (Op: {ALU_OPS[op]}):")
      print(f"       Inputs:   a=0x{a:08x}, b=0x{b:08x}")
      print(f"       Expected: {expected}")
      print(f"       Actual:   {actual}")
      all_passed = False
      break

  if all_passed:
    print(
        f"\n[SUCCESS] All {len(vectors)} test vectors passed cleanly! 0 errors."
    )
    print("Waveform dumped to 'alu_waves.vcd' for GTKWave inspection.")


if __name__ == "__main__":
  main()