# Include engine preprocessing for gKnit
# This R code reads include files before calling the Ruby engine,
# avoiding the callback deadlock and escaping issues.

# Store the original ruby engine if not already stored
if (!exists(".galaaz_original_ruby_engine", envir = .GlobalEnv)) {
  .galaaz_original_ruby_engine <- knitr::knit_engines$get("ruby")
}

# Store the original include engine if not already stored
if (!exists(".galaaz_original_include_engine", envir = .GlobalEnv)) {
  .galaaz_original_include_engine <- knitr::knit_engines$get("include")
}

# Function to resolve file path for include chunks
# Similar to inline_file_path in Ruby
galaaz_resolve_include_path <- function(filename, relative = FALSE, pwd = getwd()) {
  # Add .rb extension if not present
  if (!grepl("\\.rb$", filename)) {
    filename <- paste0(filename, ".rb")
  }

  # Start with pwd/filename
  file_path <- file.path(pwd, filename)

  # If not relative, search in common Ruby load paths
  if (!relative && !file.exists(file_path)) {
    # Common Ruby/Gem load paths
    load_paths <- c(
      file.path(Sys.getenv("HOME"), ".gem", "ruby", "*"),
      "/usr/lib/ruby/gems/*/gems/*",
      "/usr/local/lib/ruby/gems/*/gems/*",
      "/var/lib/gems/*/ruby/*",
      "/home/rbotafogo/desenv_linux/galaaz/lib"
    )
    for (pattern in load_paths) {
      candidates <- Sys.glob(file.path(pattern, filename))
      if (length(candidates) > 0 && file.exists(candidates[1])) {
        file_path <- candidates[1]
        break
      }
    }
  }

  # Return normalized path if file exists
  if (file.exists(file_path)) {
    return(normalizePath(file_path, mustWork = FALSE))
  }

  # Return NULL if file not found
  return(NULL)
}

# Wrapper for the include engine that reads file content in R
# before calling the Ruby engine
.galaaz_include_wrapper <- function(options) {
  # Get chunk label (filename)
  label <- options$label

  # Get relative option (default FALSE)
  relative <- if (!is.null(options$relative)) {
    isTRUE(options$relative)
  } else {
    FALSE
  }

  # Resolve the file path
  file_path <- galaaz_resolve_include_path(label, relative, getwd())

  if (!is.null(file_path) && file.exists(file_path)) {
    # Read file content directly in R
    content <- readLines(file_path, warn = FALSE)

    # Put content into options$code as a single string
    options$code <- paste(content, collapse = "\n")

    # Remove the file_path marker if it exists (for compatibility)
    options$file_path <- NULL
  } else {
    # File not found - set empty code and add warning
    options$code <- paste0("# File not found: ", label)
    warning(paste("Include file not found:", label))
  }

  # Call the original ruby engine (not the include engine)
  # This avoids the callback deadlock
  knitr::knit_engines$get("ruby")(options)
}

# Register the wrapper as the include engine
knitr::knit_engines$set(include = .galaaz_include_wrapper)

# Also wrap the ruby engine to ensure proper error handling
.galaaz_ruby_wrapper <- function(options) {
  tryCatch({
    # Call original ruby engine
    .galaaz_original_ruby_engine(options)
  }, error = function(e) {
    # Format error nicely
    msg <- conditionMessage(e)
    knitr::engine_output(options, code = options$code, out = paste("Error:", msg))
  })
}

# Register the wrapper as the ruby engine
knitr::knit_engines$set(ruby = .galaaz_ruby_wrapper)

# Message to confirm loading
message("gKnit include engine loaded (R-side file reading enabled)")
