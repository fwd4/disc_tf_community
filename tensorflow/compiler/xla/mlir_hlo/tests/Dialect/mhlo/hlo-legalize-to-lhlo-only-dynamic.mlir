// RUN: mlir-hlo-opt -hlo-legalize-to-lhlo -split-input-file \
// RUN:  -canonicalize -lhlo-legalize-to-tensor-op %s -o - | FileCheck %s

// CHECK-LABEL: func @dynamic_reshape
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>, %[[SHAPE:.*]]: memref<3xindex>) -> memref<?x?x?xf32>
func.func @dynamic_reshape(%lhs: tensor<?x?xf32>, %rhs: tensor<3xindex>) -> tensor<?x?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.load %[[SHAPE]][%c0]
  // CHECK: %[[DIM1:.*]] = memref.load %[[SHAPE]][%c1]
  // CHECK: %[[DIM2:.*]] = memref.load %[[SHAPE]][%c2]
  // CHECK: %[[OUTPUT:.*]] = memref.alloc(%[[DIM0]], %[[DIM1]], %[[DIM2]])
  // CHECK: "lmhlo.dynamic_reshape"(%[[ARG]], %[[SHAPE]], %[[OUTPUT]])
  // CHECK: return %[[OUTPUT]]
  %result = "mhlo.dynamic_reshape"(%lhs, %rhs)
      : (tensor<?x?xf32>, tensor<3xindex>) -> tensor<?x?x?xf32>
  func.return %result : tensor<?x?x?xf32>
}

// -----

// CHECK-LABEL: func @dynamic_broadcast_in_dim
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>, %[[SHAPE:.*]]: memref<3xindex>) -> memref<?x?x?xf32>
func.func @dynamic_broadcast_in_dim(%operand: tensor<?x?xf32>, %shape: tensor<3xindex>) -> tensor<?x?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.load %[[SHAPE]][%c0]
  // CHECK: %[[DIM1:.*]] = memref.load %[[SHAPE]][%c1]
  // CHECK: %[[DIM2:.*]] = memref.load %[[SHAPE]][%c2]
  // CHECK: %[[OUTPUT:.*]] = memref.alloc(%[[DIM0]], %[[DIM1]], %[[DIM2]])
  // CHECK: "lmhlo.dynamic_broadcast_in_dim"(%[[ARG]], %[[SHAPE]], %[[OUTPUT]])
  // CHECK: return %[[OUTPUT]]
  %result = "mhlo.dynamic_broadcast_in_dim"(%operand, %shape) {
    broadcast_dimensions = dense<[1, 2]> : tensor<2xi64>
  } : (tensor<?x?xf32>, tensor<3xindex>) -> tensor<?x?x?xf32>
  func.return %result : tensor<?x?x?xf32>
}

// -----

// CHECK-LABEL: func @dynamic_iota
// CHECK-SAME: (%[[SHAPE:.*]]: memref<2xindex>) -> memref<5x?xi32>
func.func @dynamic_iota(%arg0 : tensor<2xindex>) -> tensor<5x?xi32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.load %[[SHAPE]][%c1]
  // CHECK: %[[OUTPUT:.*]] = memref.alloc(%[[DIM0]])
  // CHECK: "lmhlo.dynamic_iota"(%[[SHAPE]], %[[OUTPUT]])
  %0 = "mhlo.dynamic_iota"(%arg0) {iota_dimension = 1 : i64} : (tensor<2xindex>) -> tensor<5x?xi32>
  func.return %0 : tensor<5x?xi32>
}

// -----

// CHECK-LABEL: func @dynamic_pad
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>, %[[VAL:.*]]: memref<f32>,
// CHECK-SAME:  %[[LOW:.*]]: memref<2xindex>, %[[HIGH:.*]]: memref<2xindex>, %[[INTER:.*]]: memref<2xindex>) -> memref<?x?xf32>
func.func @dynamic_pad(%arg0: tensor<?x?xf32>, %arg1: tensor<f32>, %arg2: tensor<2xindex>, %arg3: tensor<2xindex>, %arg4: tensor<2xindex>) -> tensor<?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.dim %[[ARG]], %c0 : memref<?x?xf32>
  // CHECK: %[[TMP1:.*]] = memref.load %[[LOW]][%c0] : memref<2xindex>
  // CHECK: %[[TMP2:.*]] = memref.load %[[HIGH]][%c0] : memref<2xindex>
  // CHECK: %[[TMP3:.*]] = memref.load %[[INTER]][%c0] : memref<2xindex>
  // CHECK: %[[TMP4:.*]] = arith.cmpi slt, %[[DIM0]], %c1 : index
  // CHECK: %[[TMP5:.*]] = arith.subi %[[DIM0]], %c1 : index
  // CHECK: %[[TMP6:.*]] = arith.select %[[TMP4]], %c0, %[[TMP5]] : index
  // CHECK: %[[TMP7:.*]] = arith.muli %[[TMP3]], %[[TMP6]] : index
  // CHECK: %[[TMP8:.*]] = arith.addi %[[TMP7]], %[[DIM0]] : index
  // CHECK: %[[TMP9:.*]] = arith.addi %[[TMP8]], %[[TMP1]] : index
  // CHECK: %[[TMP10:.*]] = arith.addi %[[TMP9]], %[[TMP2]] : index
  // CHECK: %[[TMP11:.*]] = memref.dim %[[ARG]], %c1 : memref<?x?xf32>
  // CHECK: %[[TMP12:.*]] = memref.load %[[LOW]][%c1] : memref<2xindex>
  // CHECK: %[[TMP13:.*]] = memref.load %[[HIGH]][%c1] : memref<2xindex>
  // CHECK: %[[TMP14:.*]] = memref.load %[[INTER]][%c1] : memref<2xindex>
  // CHECK: %[[TMP15:.*]] = arith.cmpi slt, %[[TMP11]], %c1 : index
  // CHECK: %[[TMP16:.*]] = arith.subi %[[TMP11]], %c1 : index
  // CHECK: %[[TMP17:.*]] = arith.select %[[TMP15]], %c0, %[[TMP16]] : index
  // CHECK: %[[TMP18:.*]] = arith.muli %[[TMP14]], %[[TMP17]] : index
  // CHECK: %[[TMP19:.*]] = arith.addi %[[TMP18]], %[[TMP11]] : index
  // CHECK: %[[TMP20:.*]] = arith.addi %[[TMP19]], %[[TMP12]] : index
  // CHECK: %[[TMP21:.*]] = arith.addi %[[TMP20]], %[[TMP13]] : index
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[TMP10]], %[[TMP21]]) : memref<?x?xf32>
  // CHECK: "lmhlo.dynamic_pad"(%[[ARG]], %[[VAL]], %[[LOW]], %[[HIGH]], %[[INTER]], %[[OUT]])
  %0 = "mhlo.dynamic_pad"(%arg0, %arg1, %arg2, %arg3, %arg4) : (tensor<?x?xf32>, tensor<f32>, tensor<2xindex>, tensor<2xindex>, tensor<2xindex>) -> tensor<?x?xf32>
  func.return %0: tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @real_dynamic_slice
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>,
// CHECK-SAME:  %[[START:.*]]: memref<2xi32>, %[[LIMIT:.*]]: memref<2xi32>, %[[STRIDE:.*]]: memref<2xi32>) -> memref<?x?xf32>
func.func @real_dynamic_slice(%arg0: tensor<?x?xf32>, %arg1: tensor<2xi32>, %arg2: tensor<2xi32>, %arg3: tensor<2xi32>) -> tensor<?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[T0:.*]] = memref.load %[[START]][%c0] : memref<2xi32>
  // CHECK: %[[T1:.*]] = memref.load %[[LIMIT]][%c0] : memref<2xi32>
  // CHECK: %[[T2:.*]] = memref.load %[[STRIDE]][%c0] : memref<2xi32>
  // CHECK: %[[T3:.*]] = arith.subi %[[T1]], %[[T0]] : i32
  // CHECK: %[[T4:.*]] = arith.addi %[[T2]], %[[T3]] : i32
  // CHECK: %[[T5:.*]] = arith.subi %[[T4]], %c1_i32 : i32
  // CHECK: %[[T6:.*]] = arith.divsi %[[T5]], %[[T2]] : i32
  // CHECK: %[[T7:.*]] = memref.load %[[START]][%c1] : memref<2xi32>
  // CHECK: %[[T8:.*]] = memref.load %[[LIMIT]][%c1] : memref<2xi32>
  // CHECK: %[[T9:.*]] = memref.load %[[STRIDE]][%c1] : memref<2xi32>
  // CHECK: %[[T10:.*]] = arith.subi %[[T8]], %[[T7]] : i32
  // CHECK: %[[T11:.*]] = arith.addi %[[T9]], %[[T10]] : i32
  // CHECK: %[[T12:.*]] = arith.subi %[[T11]], %c1_i32 : i32
  // CHECK: %[[T13:.*]] = arith.divsi %[[T12]], %[[T9]] : i32
  // CHECK: %[[T14:.*]] = arith.index_cast %[[T6]] : i32 to index
  // CHECK: %[[T15:.*]] = arith.index_cast %[[T13]] : i32 to index
  // CHECK: %[[T16:.*]] = memref.alloc(%[[T14]], %[[T15]]) : memref<?x?xf32>
  // CHECK: "lmhlo.real_dynamic_slice"(%[[ARG]], %[[START]], %[[LIMIT]], %[[STRIDE]], %[[T16]])
  %0 = "mhlo.real_dynamic_slice"(%arg0, %arg1, %arg2, %arg3) : (tensor<?x?xf32>, tensor<2xi32>, tensor<2xi32>, tensor<2xi32>) -> tensor<?x?xf32>
  func.return %0: tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @row_reduce
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>, %[[VAL:.*]]: memref<f32>) -> memref<?xf32>
func.func @row_reduce(%arg0: tensor<?x?xf32>, %arg1: tensor<f32>) -> tensor<?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.dim %[[ARG]], %c0 : memref<?x?xf32>
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[DIM0]]) : memref<?xf32>
  // CHECK: lmhlo.reduce
  // CHECK-SAME: %[[ARG]], %[[VAL]], %[[OUT]]
  // CHECK: return %[[OUT]] : memref<?xf32>
  %0 = "mhlo.reduce"(%arg0, %arg1) ({
  ^bb0(%arg2: tensor<f32>, %arg3: tensor<f32>):
    %1 = mhlo.add %arg2, %arg3 : tensor<f32>
    "mhlo.return"(%1) : (tensor<f32>) -> ()
  }) {dimensions = dense<1> : tensor<1xi64>}
      : (tensor<?x?xf32>, tensor<f32>) -> tensor<?xf32>
  func.return %0: tensor<?xf32>
}

// -----

// CHECK-LABEL: func @column_reduce
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>, %[[VAL:.*]]: memref<f32>) -> memref<?xf32>
func.func @column_reduce(%arg0: tensor<?x?xf32>, %arg1: tensor<f32>) -> tensor<?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM1:.*]] = memref.dim %[[ARG]], %c1 : memref<?x?xf32>
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[DIM1]]) : memref<?xf32>
  // CHECK: lmhlo.reduce
  // CHECK-SAME: %[[ARG]], %[[VAL]], %[[OUT]]
  // CHECK: return %[[OUT]] : memref<?xf32>
  %0 = "mhlo.reduce"(%arg0, %arg1) ({
  ^bb0(%arg2: tensor<f32>, %arg3: tensor<f32>):
    %1 = mhlo.add %arg2, %arg3 : tensor<f32>
    "mhlo.return"(%1) : (tensor<f32>) -> ()
  }) {dimensions = dense<0> : tensor<1xi64>}
      : (tensor<?x?xf32>, tensor<f32>) -> tensor<?xf32>
  func.return %0: tensor<?xf32>
}

// -----

// CHECK-LABEL: func @transpose
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>) -> memref<?x?xf32>
func.func @transpose(%arg0: tensor<?x?xf32>) -> tensor<?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.dim %[[ARG]], %c0 : memref<?x?xf32>
  // CHECK: %[[DIM1:.*]] = memref.dim %[[ARG]], %c1 : memref<?x?xf32>
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[DIM1]], %[[DIM0]]) : memref<?x?xf32>
  // CHECK: "lmhlo.transpose"(%[[ARG]], %[[OUT]])
  %0 = "mhlo.transpose"(%arg0) {permutation = dense<[1,0]> : tensor<2xi64>} : (tensor<?x?xf32>) -> tensor<?x?xf32>
  func.return %0: tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @concatenate
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?xi32>, %[[ARG1:.*]]: memref<?x?xi32>, %[[ARG2:.*]]: memref<?x?xi32>) -> memref<?x?xi32>
func.func @concatenate(%a: tensor<?x?xi32>, %b: tensor<?x?xi32>, %c: tensor<?x?xi32>) -> tensor<?x?xi32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[ARG0_DIM0:.*]] = memref.dim %[[ARG0]], %c0 : memref<?x?xi32>
  // CHECK: %[[ARG0_DIM1:.*]] = memref.dim %[[ARG0]], %c1 : memref<?x?xi32>
  // CHECK: %[[ARG1_DIM1:.*]] = memref.dim %[[ARG1]], %c1 : memref<?x?xi32>
  // CHECK: %[[ARG2_DIM1:.*]] = memref.dim %[[ARG2]], %c1 : memref<?x?xi32>
  // CHECK: %[[TMP:.*]] = arith.addi %[[ARG0_DIM1]], %[[ARG1_DIM1]] : index
  // CHECK: %[[OUT_DIM1:.*]] = arith.addi %[[TMP]], %[[ARG2_DIM1]] : index
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[ARG0_DIM0]], %[[OUT_DIM1]]) : memref<?x?xi32>
  // CHECK: "lmhlo.concatenate"(%[[ARG0]], %[[ARG1]], %[[ARG2]], %[[OUT]])
  %concat = "mhlo.concatenate"(%a, %b, %c) {
    dimension = 1
  } : (tensor<?x?xi32>, tensor<?x?xi32>, tensor<?x?xi32>) -> tensor<?x?xi32>
  func.return %concat : tensor<?x?xi32>
}

// -----

// CHECK-LABEL: func @gather
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?xf32>, %[[ARG1:.*]]: memref<?xi32>) -> memref<?x?xf32>
func.func @gather(%operand: tensor<?x?xf32>, %idxs: tensor<?xi32>)
    -> tensor<?x?xf32> {
  // CHECK: %[[ARG1_DIM0:.*]] = memref.dim %[[ARG1]], %c0 : memref<?xi32>
  // CHECK: %[[TMP:.*]] = memref.alloc(%0) : memref<?x7xf32>
  // CHECK: %[[OUT:.*]] = memref.cast %[[TMP:.*]] : memref<?x7xf32> to memref<?x?xf32>
  // CHECK: "lmhlo.gather"(%[[ARG0]], %[[ARG1]], %[[OUT]])
  %result =
    "mhlo.gather"(%operand, %idxs)
      { dimension_numbers = #mhlo.gather<
          collapsed_slice_dims = [0],
          index_vector_dim = 1,
          offset_dims = [1],
          start_index_map = [0],
      >,
      indices_are_sorted = false,
      slice_sizes = dense<[1, 7]> : tensor<2xi64>
      }
      : (tensor<?x?xf32>, tensor<?xi32>) -> tensor<?x?xf32>
  func.return %result : tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @dynamic_gather
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?xf32>, %[[ARG1:.*]]: memref<?xi32>, %[[ARG2:.*]]: memref<2xi32>) -> memref<?x?xf32>
func.func @dynamic_gather(%operand: tensor<?x?xf32>, %idxs: tensor<?xi32>, %slice_sizes: tensor<2xi32>)
    -> tensor<?x?xf32> {
  // CHECK-DAG: %[[SIZE1_i32:.*]] = memref.load %[[ARG2]][%c1] : memref<2xi32>
  // CHECK-DAG: %[[ARG1_DIM0:.*]] = memref.dim %[[ARG1]], %c0 : memref<?xi32>
  // CHECK-DAG: %[[SIZE:.*]] = arith.index_cast %[[SIZE1_i32]] : i32 to index
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[ARG1_DIM0]], %[[SIZE]]) : memref<?x?xf32>
  // CHECK: "lmhlo.dynamic_gather"(%[[ARG0]], %[[ARG1]], %[[ARG2]], %[[OUT]])
  %result =
    "mhlo.dynamic_gather"(%operand, %idxs, %slice_sizes) {
      dimension_numbers = #mhlo.gather<
        collapsed_slice_dims = [0],
        index_vector_dim = 1,
        offset_dims = [1],
        start_index_map = [0],
      >,
      indices_are_sorted = false
    } : (tensor<?x?xf32>, tensor<?xi32>, tensor<2xi32>) -> tensor<?x?xf32>
  func.return %result : tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @logistic
// CHECK-SAME: (%[[ARG:.*]]: memref<?x?xf32>) -> memref<?x?xf32>
func.func @logistic(%arg0: tensor<?x?xf32>) -> tensor<?x?xf32> {
  // CHECK-NOT: tensor_load
  // CHECK: %[[DIM0:.*]] = memref.dim %[[ARG]], %c0
  // CHECK: %[[DIM1:.*]] = memref.dim %[[ARG]], %c1
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[DIM0]], %[[DIM1]]) : memref<?x?xf32>
  // CHECK: "lmhlo.logistic"(%[[ARG]], %[[OUT]])
  %0 = "mhlo.logistic"(%arg0) : (tensor<?x?xf32>) -> tensor<?x?xf32>
  func.return %0: tensor<?x?xf32>
}

// CHECK-LABEL: func @dot
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?xf32>, %[[ARG1:.*]]: memref<?x?xf32>)
func @dot(%arg0: tensor<?x?xf32>, %arg1: tensor<?x?xf32>) -> tensor<?x?xf32> {
  // CHECK-DAG: %[[CONST_ZERO:.*]] = constant 0 : index
  // CHECK-DAG: %[[CONST_ONE:.*]] = constant 1 : index
  // CHECK-DAG: %[[OUT_DIM0:.*]] = memref.dim %[[ARG0]], %[[CONST_ZERO]] : memref<?x?xf32>
  // CHECK-DAG: %[[OUT_DIM1:.*]] = memref.dim %[[ARG1]], %[[CONST_ONE]] : memref<?x?xf32>
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[OUT_DIM0]], %[[OUT_DIM1]]) : memref<?x?xf32>
  // CHECK: "lmhlo.dot"(%[[ARG0]], %[[ARG1]], %[[OUT]])
  %0 = "mhlo.dot"(%arg0, %arg1) : (tensor<?x?xf32>, tensor<?x?xf32>) -> tensor<?x?xf32>
  return %0: tensor<?x?xf32>
}

// -----

// CHECK-LABEL: func @dot_general
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?x?xf32>, %[[ARG1:.*]]: memref<?x?x?xf32>)
func @dot_general(%arg0: tensor<?x?x?xf32>, %arg1: tensor<?x?x?xf32>) -> tensor<?x?x?xf32> {
  // CHECK-DAG: %[[BATCH_IDX:.*]] = constant 0 : index
  // CHECK-DAG: %[[LHS_IDX:.*]] = constant 1 : index
  // CHECK-DAG: %[[RHS_IDX:.*]] = constant 2 : index
  // CHECK-DAG: %[[BATCH_DIM:.*]] = memref.dim %[[ARG0]], %[[BATCH_IDX]] : memref<?x?x?xf32>
  // CHECK-DAG: %[[LHS_DIM:.*]] = memref.dim %[[ARG0]], %[[LHS_IDX]] : memref<?x?x?xf32>
  // CHECK-DAG: %[[RHS_DIM:.*]] = memref.dim %[[ARG1]], %[[RHS_IDX]] : memref<?x?x?xf32>
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[BATCH_DIM]], %[[LHS_DIM]], %[[RHS_DIM]]) : memref<?x?x?xf32>
  // CHECK: "lmhlo.dot_general"(%[[ARG0]], %[[ARG1]], %[[OUT]])
  %0 = "mhlo.dot_general"(%arg0, %arg1) { dot_dimension_numbers = {
    lhs_batching_dimensions = dense<0> : tensor<1xi64>,
    lhs_contracting_dimensions = dense<[2]> : tensor<1xi64>,
    rhs_batching_dimensions = dense<0> : tensor<1xi64>,
    rhs_contracting_dimensions = dense<1> : tensor<1xi64>
  }} : (tensor<?x?x?xf32>, tensor<?x?x?xf32>) -> tensor<?x?x?xf32>
  return %0: tensor<?x?x?xf32>
}

// -----

// CHECK-LABEL: func @conv
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?x?x?xf32>, %[[ARG1:.*]]: memref<?x?x?x?xf32>)
func @conv(%arg0: tensor<?x?x?x?xf32>, %arg1: tensor<?x?x?x?xf32>)
  -> tensor<?x?x?x?xf32> {
  %0 = "mhlo.convolution"(%arg0, %arg1) {
    batch_group_count = 1 : i64,
    dimension_numbers = {
      // CHECK-DAG: %[[C0_BATCH_IDX_OR_KERNEL_X_IDX:.*]] = constant 0 : index
      // CHECK-DAG: %[[BATCH_DIM:.*]] = memref.dim %[[ARG0]], %[[C0_BATCH_IDX_OR_KERNEL_X_IDX]] : memref<?x?x?x?xf32>
      input_batch_dimension = 0 : i64,
      input_feature_dimension = 3 : i64,
      input_spatial_dimensions = dense<[1, 2]> : tensor<2xi64>,
      kernel_input_feature_dimension = 2 : i64,
      // CHECK-DAG: %[[C3_FEATURE_IDX_OR_PAD_X:.*]] = constant 3 : index
      // Note that padding in x dim is 1 + 2 = 3, as in `padding` attribute.
      // CHECK-DAG: %[[FEATURE_DIM:.*]] = memref.dim %[[ARG1]], %[[C3_FEATURE_IDX_OR_PAD_X]] : memref<?x?x?x?xf32>
      kernel_output_feature_dimension = 3 : i64,
      kernel_spatial_dimensions = dense<[0, 1]> : tensor<2xi64>,
      output_batch_dimension = 0 : i64,
      output_feature_dimension = 3 : i64,
      // CHECK-DAG: %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX:.*]] = constant 1 : index
      // CHECK-DAG: %[[C2_IN_OUT_Y_IDX_OR_LHS_DIL_OR_STRIDE_X:.*]] = constant 2 : index
      output_spatial_dimensions = dense<[1, 2]> : tensor<2xi64>
    },
    feature_group_count = 1 : i64,
    // lhs_dilation = dense<1> : tensor<2xi64>,
    // CHECK-DAG: %[[C4_PAD_Y:.*]] = constant 4 : index
    padding = dense<[[1, 2], [3, 1]]> : tensor<2x2xi64>,
    precision_config = ["DEFAULT", "DEFAULT"],
    rhs_dilation = dense<[2, 1]> : tensor<2xi64>,
    window_strides = dense<[2, 1]> : tensor<2xi64>

  } : (tensor<?x?x?x?xf32>, tensor<?x?x?x?xf32>) -> tensor<?x?x?x?xf32>

  // Calculate first spatial dimension, which we name dim-x here.
  // CHECK-DAG: %[[IN_X_DIM:.*]] = memref.dim %[[ARG0]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]] : memref<?x?x?x?xf32>
  // CHECK: %[[IN_X_SIZE_WITH_PAD:.*]] = addi %[[IN_X_DIM]], %[[C3_FEATURE_IDX_OR_PAD_X]]
  // CHECK: %[[KERNEL_X_DIM:.*]] = memref.dim %[[ARG1]], %[[C0_BATCH_IDX_OR_KERNEL_X_IDX]]
  // CHECK: %[[KXD_MINUS_ONE:.*]] = subi %[[KERNEL_X_DIM]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]
  // CHECK: %[[KXD_MINUS_ONE_MUL_D:.*]] = muli %[[KXD_MINUS_ONE]], %[[C2_IN_OUT_Y_IDX_OR_LHS_DIL_OR_STRIDE_X]]
  // CHECK: %[[KERNEL_X_WITH_DIL:.*]] = addi %[[KXD_MINUS_ONE_MUL_D]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]
  // CHECK: %[[INX_MINUS_KX:.*]] = subi %[[IN_X_SIZE_WITH_PAD]], %[[KERNEL_X_WITH_DIL]]
  // CHECK: %[[INX_MINUS_KX_DIV_STRIDE:.*]] = divi_signed %[[INX_MINUS_KX]], %[[C2_IN_OUT_Y_IDX_OR_LHS_DIL_OR_STRIDE_X]]
  // CHECK: %[[OUT_X_SIZE:.*]] = addi %[[INX_MINUS_KX_DIV_STRIDE]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]

  // Calculate second spatial dimension, which we name dim-y here.
  // CHECK-DAG: %[[IN_Y_DIM:.*]] = memref.dim %[[ARG0]], %[[C2_IN_OUT_Y_IDX_OR_LHS_DIL_OR_STRIDE_X]] : memref<?x?x?x?xf32>
  // CHECK: %[[IN_Y_SIZE_WITH_PAD:.*]] = addi %[[IN_Y_DIM]], %[[C4_PAD_Y]]
  // CHECK: %[[KERNEL_Y_DIM:.*]] = memref.dim %[[ARG1]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]
  // CHECK: %[[INY_MINUS_KY:.*]] = subi %[[IN_Y_SIZE_WITH_PAD]], %[[KERNEL_Y_DIM]]
  // CHECK: %[[OUT_Y_SIZE:.*]] = addi %[[INY_MINUS_KY]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]

  // CHECK: %[[OUT:.*]] = memref.alloc(%[[BATCH_DIM]], %[[OUT_X_SIZE]], %[[OUT_Y_SIZE]], %[[FEATURE_DIM]]) : memref<?x?x?x?xf32>
  // CHECK: lmhlo.convolution(%[[ARG0]], %[[ARG1]], %[[OUT]])
  return %0 : tensor<?x?x?x?xf32>
}

// -----

// CHECK-LABEL: func @dynamic_conv
// CHECK-SAME: (%[[ARG0:.*]]: memref<?x?x?x?xf32>, %[[ARG1:.*]]: memref<?x?x?x?xf32>, %[[ARG2:.*]]: memref<4xi32>)
func @dynamic_conv(%arg0: tensor<?x?x?x?xf32>, %arg1: tensor<?x?x?x?xf32>, %arg2: tensor<4xi32>)
  -> tensor<?x?x?x?xf32> {
  %0 = "mhlo.dynamic_conv"(%arg0, %arg1, %arg2) {
    batch_group_count = 1 : i64,
    dimension_numbers = {
      // CHECK-DAG: %[[C0_BATCH_IDX_OR_KERNEL_X_IDX:.*]] = constant 0 : index
      input_batch_dimension = 0 : i64,
      input_feature_dimension = 3 : i64,
      // CHECK-DAG: %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX:.*]] = constant 1 : index
      // CHECK-DAG: %[[C2_IN_OUT_Y_IDX:.*]] = constant 2 : index
      input_spatial_dimensions = dense<[1, 2]> : tensor<2xi64>,
      kernel_input_feature_dimension = 2 : i64,
      // CHECK-DAG: %[[C3_FEATURE_IDX:.*]] = constant 3 : index
      // Note that padding in x dim is 1 + 2 = 3, as in `padding` attribute.
      kernel_output_feature_dimension = 3 : i64,
      kernel_spatial_dimensions = dense<[0, 1]> : tensor<2xi64>,
      output_batch_dimension = 0 : i64,
      output_feature_dimension = 3 : i64,
      output_spatial_dimensions = dense<[1, 2]> : tensor<2xi64>
    },
    feature_group_count = 1 : i64,
    // lhs_dilation = dense<1> : tensor<2xi64>,
    precision_config = ["DEFAULT", "DEFAULT"],
    rhs_dilation = dense<[2, 1]> : tensor<2xi64>,
    window_strides = dense<[2, 1]> : tensor<2xi64>

  } : (tensor<?x?x?x?xf32>, tensor<?x?x?x?xf32>, tensor<4xi32>) -> tensor<?x?x?x?xf32>
  // CHECK-DAG: %[[C1_I32:.*]] = constant 1 : i32
  // CHECK-DAG: %[[C2_I32_LHS_DIL_OR_STRIDE_X:.*]] = constant 2 : i32

  // Calculate paddings.
  // CHECK-DAG: %[[PAD_X_L:.*]] = memref.load %[[ARG2]][%[[C0_BATCH_IDX_OR_KERNEL_X_IDX]]]
  // CHECK-DAG: %[[PAD_X_H:.*]] = memref.load %[[ARG2]][%[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]]
  // CHECK-DAG: %[[PAD_Y_L:.*]] = memref.load %[[ARG2]][%[[C2_IN_OUT_Y_IDX]]]
  // CHECK-DAG: %[[PAD_Y_H:.*]] = memref.load %[[ARG2]][%[[C3_FEATURE_IDX]]]

  // Batch dim and feature dim.
  // CHECK-DAG: %[[BATCH_DIM:.*]] = memref.dim %[[ARG0]], %[[C0_BATCH_IDX_OR_KERNEL_X_IDX]] : memref<?x?x?x?xf32>
  // CHECK-DAG: %[[FEATURE_DIM:.*]] = memref.dim %[[ARG1]], %[[C3_FEATURE_IDX]] : memref<?x?x?x?xf32>

  // Calculate first spatial dimension, which we name dim-x here.
  // CHECK-DAG: %[[IN_X_DIM_INDEX:.*]] = memref.dim %[[ARG0]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]] : memref<?x?x?x?xf32>
  // CHECK: %[[IN_X_DIM:.*]] = index_cast %[[IN_X_DIM_INDEX]] : index to i32
  // CHECK-DAG: %[[PAD_X:.*]] = addi %[[PAD_X_L]], %[[PAD_X_H]]
  // CHECK: %[[IN_X_SIZE_WITH_PAD:.*]] = addi %[[IN_X_DIM]], %[[PAD_X]]
  // CHECK: %[[KERNEL_X_DIM_INDEX:.*]] = memref.dim %[[ARG1]], %[[C0_BATCH_IDX_OR_KERNEL_X_IDX]]
  // CHECK: %[[KERNEL_X_DIM:.*]] = index_cast %[[KERNEL_X_DIM_INDEX]] : index to i32
  // CHECK: %[[KXD_MINUS_ONE:.*]] = subi %[[KERNEL_X_DIM]], %[[C1_I32]]
  // CHECK: %[[KXD_MINUS_ONE_MUL_D:.*]] = muli %[[KXD_MINUS_ONE]], %[[C2_I32_LHS_DIL_OR_STRIDE_X]]
  // CHECK: %[[KERNEL_X_WITH_DIL:.*]] = addi %[[KXD_MINUS_ONE_MUL_D]], %[[C1_I32]]
  // CHECK: %[[INX_MINUS_KX:.*]] = subi %[[IN_X_SIZE_WITH_PAD]], %[[KERNEL_X_WITH_DIL]]
  // CHECK: %[[INX_MINUS_KX_DIV_STRIDE:.*]] = divi_signed %[[INX_MINUS_KX]], %[[C2_I32_LHS_DIL_OR_STRIDE_X]]
  // CHECK: %[[OUT_X_SIZE:.*]] = addi %[[INX_MINUS_KX_DIV_STRIDE]], %[[C1_I32]]

  // Calculate second spatial dimension, which we name dim-y here.
  // CHECK-DAG: %[[IN_Y_DIM_INDEX:.*]] = memref.dim %[[ARG0]], %[[C2_IN_OUT_Y_IDX]] : memref<?x?x?x?xf32>
  // CHECK: %[[IN_Y_DIM:.*]] = index_cast %[[IN_Y_DIM_INDEX]] : index to i32
  // CHECK-DAG: %[[PAD_Y:.*]] = addi %[[PAD_Y_L]], %[[PAD_Y_H]]
  // CHECK: %[[IN_Y_SIZE_WITH_PAD:.*]] = addi %[[IN_Y_DIM]], %[[PAD_Y]]
  // CHECK: %[[KERNEL_Y_DIM_INDEX:.*]] = memref.dim %[[ARG1]], %[[C1_IN_OUT_X_IDX_OR_KERNEL_Y_IDX]]
  // CHECK: %[[KERNEL_Y_DIM:.*]] = index_cast %[[KERNEL_Y_DIM_INDEX]] : index to i32
  // CHECK: %[[INY_MINUS_KY:.*]] = subi %[[IN_Y_SIZE_WITH_PAD]], %[[KERNEL_Y_DIM]]
  // CHECK: %[[OUT_Y_SIZE:.*]] = addi %[[INY_MINUS_KY]], %[[C1_I32]]

  // CHECK: %[[OUT_X_SIZE_INDEX:.*]] = index_cast %[[OUT_X_SIZE]] : i32 to index
  // CHECK: %[[OUT_Y_SIZE_INDEX:.*]] = index_cast %[[OUT_Y_SIZE]] : i32 to index
  // CHECK: %[[OUT:.*]] = memref.alloc(%[[BATCH_DIM]], %[[OUT_X_SIZE_INDEX]], %[[OUT_Y_SIZE_INDEX]], %[[FEATURE_DIM]]) : memref<?x?x?x?xf32>
  // CHECK: "lmhlo.dynamic_conv"(%[[ARG0]], %[[ARG1]], %[[ARG2]], %[[OUT]])
  return %0 : tensor<?x?x?x?xf32>
}
