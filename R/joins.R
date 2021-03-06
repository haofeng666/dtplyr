#' Join data table tbls.
#'
#' See \code{\link{join}} for a description of the general purpose of the
#' functions.
#'
#' @inheritParams dplyr::join
#' @param x,y tbls to join
#' @param ... Included for compatibility with generic; otherwise ignored.
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#'
#' if (require("Lahman")) {
#' batting_dt <- tbl_dt(Batting)
#' person_dt <- tbl_dt(Master)
#'
#' # Inner join: match batting and person data
#' inner_join(batting_dt, person_dt)
#'
#' # Left join: keep batting data even if person missing
#' left_join(batting_dt, person_dt)
#'
#' # Semi-join: find batting data for top 4 teams, 2010:2012
#' grid <- expand.grid(
#'   teamID = c("WAS", "ATL", "PHI", "NYA"),
#'   yearID = 2010:2012)
#' top4 <- semi_join(batting_dt, grid, copy = TRUE)
#'
#' # Anti-join: find batting data with out player data
#' anti_join(batting_dt, person_dt)
#' }
#' @name join.tbl_dt
NULL

join_dt <- function(op) {
  # nocov start
  template <- substitute(function(x, y, by = NULL, copy = FALSE, ...) {
    by <- dplyr::common_by(by, x, y)
    if (!identical(by$x, by$y)) {
      stop("Data table joins must be on same key", call. = FALSE)
    }
    y <- dplyr::auto_copy(x, y, copy = copy)

    x <- data.table::copy(x)
    y <- data.table::copy(y)
    data.table::setkeyv(x, by$x)
    data.table::setkeyv(y, by$x)
    out <- op
    grouped_dt(out, groups(x))
  })

  f <- eval(template, parent.frame())
  attr(f, "srcref") <- NULL # fix so prints correctly
  f
  # nocov end
}

#' @export
#' @rdname join.tbl_dt
#' @importFrom dplyr inner_join
inner_join.data.table <- join_dt({merge(x, y, by = by$x, allow.cartesian = TRUE)})

#' @export
#' @importFrom dplyr left_join
#' @rdname join.tbl_dt
left_join.data.table  <- join_dt({merge(x, y, by = by$x, all.x = TRUE, allow.cartesian = TRUE)})

#' @export
#' @importFrom dplyr right_join
#' @rdname join.tbl_dt
right_join.data.table  <- join_dt(merge(x, y, by = by$x, all.y = TRUE, allow.cartesian = TRUE))

#' @export
#' @importFrom dplyr semi_join
#' @rdname join.tbl_dt
semi_join.data.table  <- join_dt({
  # http://stackoverflow.com/questions/18969420/perform-a-semi-join-with-data-table
  w <- unique(x[y, which = TRUE, allow.cartesian = TRUE])
  w <- w[!is.na(w)]
  x[w]
})

#' @export
#' @importFrom dplyr anti_join
#' @rdname join.tbl_dt
anti_join.data.table <- join_dt({x[!y, allow.cartesian = TRUE]})

#' @export
#' @importFrom dplyr full_join
#' @rdname join.tbl_dt
# http://stackoverflow.com/a/15170956/946850
full_join.data.table <- join_dt({merge(x, y, by = by$x, all = TRUE, allow.cartesian = TRUE)})
