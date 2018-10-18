x <- matrix(runif(1000000), 1000, 1000)
mutual_R <- function(joint_dist) {
 joint_dist <- joint_dist/sum(joint_dist)
 mutual_information <- 0
 num_rows <- nrow(joint_dist)
 num_cols <- ncol(joint_dist)
 colsums <- colSums(joint_dist)
 rowsums <- rowSums(joint_dist)
 for(i in seq_along(1:num_rows)){
  for(j in seq_along(1:num_cols)){
   temp <- log((joint_dist[i,j]/(colsums[j]*rowsums[i])))
   if(!is.finite(temp)){
    temp = 0
   }
   mutual_information <-
    mutual_information + joint_dist[i,j] * temp
  }
 }
 mutual_information
}
system.time(mutual_R(x))
