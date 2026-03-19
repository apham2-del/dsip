#' Compute Jaccard similarity between two cluster label vectors
#'
#' @param x Numeric vector of cluster memberships (encoded as integers).
#' @param y Numeric vector of cluster memberships (encoded as integers).
#'
#' @returns Computed Jaccard similarity metric according to Ben-Hur (2001).
jaccard <- function(x, y) {

  n <- length(x) # length of x; number of samples

  # step 1: recode cluster label vectors into binary matrix representations
  # Note: subtract diagonal of 1's since C_{ii} = 0 by definition
  Cx <- outer(X = x, Y = x, FUN = function(a, b) {a == b}) - diag(n)
  Cy <- outer(X = y, Y = y, FUN = function(a, b) {a == b}) - diag(n)

  # compute Jaccard similarity
  Cxy_prod <- sum(Cx * Cy)
  j <- Cxy_prod / (sum(Cx^2) + sum(Cy^2) - Cxy_prod)
  return(j)
}
