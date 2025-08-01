! RUN: bbc -emit-hlfir -fopenmp -o - %s | FileCheck %s
! RUN: %flang_fc1 -emit-hlfir -fopenmp -o - %s | FileCheck %s

! regression test for crash

program reduce
integer :: i = 0
integer :: r = 0

!$omp parallel do reduction(min:r)
do i=0,10
   r = i
enddo
!$omp end parallel do

print *,r

end program

! CHECK-LABEL:   omp.declare_reduction @min_i32 : i32 init {
! CHECK:         ^bb0(%[[VAL_0:.*]]: i32):
! CHECK:           %[[VAL_1:.*]] = arith.constant 2147483647 : i32
! CHECK:           omp.yield(%[[VAL_1]] : i32)

! CHECK-LABEL:   } combiner {
! CHECK:         ^bb0(%[[VAL_0:.*]]: i32, %[[VAL_1:.*]]: i32):
! CHECK:           %[[VAL_2:.*]] = arith.minsi %[[VAL_0]], %[[VAL_1]] : i32
! CHECK:           omp.yield(%[[VAL_2]] : i32)
! CHECK:         }

! CHECK-LABEL:   func.func @_QQmain() attributes {fir.bindc_name = "REDUCE"} {
! CHECK:           %[[VAL_0:.*]] = fir.address_of(@_QFEi) : !fir.ref<i32>
! CHECK:           %[[VAL_1:.*]]:2 = hlfir.declare %[[VAL_0]] {uniq_name = "_QFEi"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
! CHECK:           %[[VAL_2:.*]] = fir.address_of(@_QFEr) : !fir.ref<i32>
! CHECK:           %[[VAL_3:.*]]:2 = hlfir.declare %[[VAL_2]] {uniq_name = "_QFEr"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
! CHECK:           omp.parallel {
! CHECK:             %[[VAL_6:.*]] = arith.constant 0 : i32
! CHECK:             %[[VAL_7:.*]] = arith.constant 10 : i32
! CHECK:             %[[VAL_8:.*]] = arith.constant 1 : i32
! CHECK:             omp.wsloop private(@{{.*}} %{{.*}}#0 -> %[[VAL_4:.*]] : !fir.ref<i32>) reduction(@min_i32 %[[VAL_3]]#0 -> %[[VAL_9:.*]] : !fir.ref<i32>) {
! CHECK-NEXT:          omp.loop_nest (%[[VAL_10:.*]]) : i32 = (%[[VAL_6]]) to (%[[VAL_7]]) inclusive step (%[[VAL_8]]) {
! CHECK:                 %[[VAL_5:.*]]:2 = hlfir.declare %[[VAL_4]] {uniq_name = "_QFEi"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
! CHECK:                 %[[VAL_11:.*]]:2 = hlfir.declare %[[VAL_9]] {uniq_name = "_QFEr"} : (!fir.ref<i32>) -> (!fir.ref<i32>, !fir.ref<i32>)
! CHECK:                 hlfir.assign %[[VAL_10]] to %[[VAL_5]]#0 : i32, !fir.ref<i32>
! CHECK:                 %[[VAL_12:.*]] = fir.load %[[VAL_5]]#0 : !fir.ref<i32>
! CHECK:                 hlfir.assign %[[VAL_12]] to %[[VAL_11]]#0 : i32, !fir.ref<i32>
! CHECK:                 omp.yield
! CHECK:               }
! CHECK:             omp.terminator
! CHECK:           }
