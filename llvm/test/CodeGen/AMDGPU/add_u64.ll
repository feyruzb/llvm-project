; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc -mtriple=amdgcn -mcpu=gfx1200 < %s | FileCheck -check-prefixes=GCN,GFX12 %s
; RUN: llc -mtriple=amdgcn -mcpu=gfx1250 < %s | FileCheck -check-prefixes=GCN,GFX1250 %s

define amdgpu_ps <2 x float> @test_add_u64_vv(i64 %a, i64 %b) {
; GFX12-LABEL: test_add_u64_vv:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, v0, v2
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, v1, v3, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_vv:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], v[0:1], v[2:3]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, %b
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_vs(i64 %a, i64 inreg %b) {
; GFX12-LABEL: test_add_u64_vs:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, v0, s0
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, s1, v1, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_vs:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], s[0:1], v[0:1]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, %b
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_sv(i64 inreg %a, i64 %b) {
; GFX12-LABEL: test_add_u64_sv:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, s0, v0
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, s1, v1, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_sv:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], s[0:1], v[0:1]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, %b
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_ss(i64 inreg %a, i64 inreg %b) {
; GCN-LABEL: test_add_u64_ss:
; GCN:       ; %bb.0:
; GCN-NEXT:    s_add_nc_u64 s[0:1], s[0:1], s[2:3]
; GCN-NEXT:    s_delay_alu instid0(SALU_CYCLE_1)
; GCN-NEXT:    v_dual_mov_b32 v0, s0 :: v_dual_mov_b32 v1, s1
; GCN-NEXT:    ; return to shader part epilog
  %add = add i64 %a, %b
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_v_inline_lit(i64 %a) {
; GFX12-LABEL: test_add_u64_v_inline_lit:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, v0, 5
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, 0, v1, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_v_inline_lit:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], 5, v[0:1]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, 5
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_v_small_imm(i64 %a) {
; GFX12-LABEL: test_add_u64_v_small_imm:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, 0x1f4, v0
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, 0, v1, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_v_small_imm:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], 0x1f4, v[0:1]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, 500
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_v_64bit_imm(i64 %a) {
; GFX12-LABEL: test_add_u64_v_64bit_imm:
; GFX12:       ; %bb.0:
; GFX12-NEXT:    v_add_co_u32 v0, vcc_lo, 0x3b9ac9ff, v0
; GFX12-NEXT:    s_delay_alu instid0(VALU_DEP_1)
; GFX12-NEXT:    v_add_co_ci_u32_e64 v1, null, 1, v1, vcc_lo
; GFX12-NEXT:    ; return to shader part epilog
;
; GFX1250-LABEL: test_add_u64_v_64bit_imm:
; GFX1250:       ; %bb.0:
; GFX1250-NEXT:    v_add_nc_u64_e32 v[0:1], lit64(0x13b9ac9ff), v[0:1]
; GFX1250-NEXT:    ; return to shader part epilog
  %add = add i64 %a, 5294967295
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}

define amdgpu_ps <2 x float> @test_add_u64_s_small_imm(i64 inreg %a) {
; GCN-LABEL: test_add_u64_s_small_imm:
; GCN:       ; %bb.0:
; GCN-NEXT:    s_add_nc_u64 s[0:1], s[0:1], 0x1f4
; GCN-NEXT:    s_delay_alu instid0(SALU_CYCLE_1)
; GCN-NEXT:    v_dual_mov_b32 v0, s0 :: v_dual_mov_b32 v1, s1
; GCN-NEXT:    ; return to shader part epilog
  %add = add i64 %a, 500
  %ret = bitcast i64 %add to <2 x float>
  ret <2 x float> %ret
}
