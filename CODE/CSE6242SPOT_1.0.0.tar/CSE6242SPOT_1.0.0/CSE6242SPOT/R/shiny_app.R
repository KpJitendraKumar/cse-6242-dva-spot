
#' Run the SPOT app
#' @description Runs the SPOT app. You will need python with libraries (numpy, osmnx, networkx, os, sklearn, pandas).
#' Pass the python executable path while calling the function.
#' To get the python path you can use
#'
#' python3 -c "import sys; print(sys.executable)".
#'
#' Or you can go to: https://stackoverflow.com/questions/749711/how-to-get-the-python-exe-location-programmatically
#'
#'
#' @param py_path path to the python executable. See decription for more information
#' @examples
#' runSPOT(py_path = "path/to/pyhton")
#' @export

runSPOT <- function(py_path = NULL) {

  if (is.null(py_path)){
    py_path <- Sys.which("python")
  }
  .GlobalEnv$.path <- py_path
  on.exit(rm(.path, envir=.GlobalEnv))

  appDir <- system.file("shiny", "safe_path", package = "CSE6242SPOT")

  if (appDir == "") {
    stop("Could not find example directory. Try re-installing `CSE6242SPOT`. Contact <apriyam3@gatech.com", call. = FALSE)
  }

  shiny::runApp(appDir, launch.browser = TRUE)
}
