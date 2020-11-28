get_path <- function(origin, dest, path_type){
  
  #y = path_finder(c(33.771331, -84.395248), c(33.779853, -84.384140), path_type)
  y <- path_finder(origin, dest, path_type)
  y_ <- unlist(y)
  
  return(y_)
}