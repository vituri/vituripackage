#' Check if two objects are identical
#' @param a an object.
#' @param b an object.
#' @return TRUE if a and b are identical; FALSE otherwise.
#' @export
`%is%` = function(a, b) {
  identical(a, b)
}
