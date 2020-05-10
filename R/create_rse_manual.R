#' Internal function for creating a recount3 RangedSummarizedExperiment object
#'
#' This function is used internally by `create_rse()` to construct a `recount3`
#' [RangedSummarizedExperiment-class][SummarizedExperiment::RangedSummarizedExperiment-class]
#' object that contains the base-pair coverage counts at the `gene` or `exon`
#' feature level for a given annotation.
#'
#' @param type  A `character(1)` specifying whether you want to access gene
#' counts or exon counts.
#' @inheritParams file_locate_url
#' @inheritParams file_retrieve
#'
#' @return A
#'  [RangedSummarizedExperiment-class][SummarizedExperiment::RangedSummarizedExperiment-class]
#'  object.
#' @export
#' @importFrom SummarizedExperiment SummarizedExperiment
#' @importFrom S4Vectors DataFrame
#' @importFrom rtracklayer import
#' @references
#'
#' <https://doi.org/10.12688/f1000research.12223.1> for details on the
#' base-pair coverage counts used in recount2 and recount3.
#'
#' @family internal functions for accessing the recount3 data
#' @examples
#'
#' rse_gene_ERP001942_manual <- create_rse_manual("ERP001942", "data_sources/sra")
#' rse_gene_ERP001942_manual
create_rse_manual <- function(project,
    project_home = project_home_available(
        organism = organism,
        recount3_url = recount3_url
    ),
    type = c("gene", "exon"),
    organism = c("human", "mouse"),
    annotation = annotation_options(organism),
    bfc = BiocFileCache::BiocFileCache(),
    recount3_url = "http://snaptron.cs.jhu.edu/data/temp/recount3") {
    type <- match.arg(type)
    organism <- match.arg(organism)
    project_home <- match.arg(project_home)
    annotation <- match.arg(annotation)

    ## First the metadata which is the smallest
    message(paste(Sys.time(), "downloading and reading the metadata"))
    metadata <- read_metadata(file_retrieve(
        url = file_locate_url(
            project = project,
            project_home = project_home,
            type = "metadata",
            organism = organism,
            annotation = annotation,
            recount3_url = recount3_url
        ),
        bfc = bfc
    ))

    ## Add the URLs to the BigWig files
    metadata$BigWigURL <- file_locate_url(
        project = project,
        project_home = project_home,
        type = "bw",
        organism = organism,
        annotation = annotation,
        recount3_url = recount3_url,
        sample = metadata$run_acc
    )


    message(paste(
        Sys.time(),
        "downloading and reading the feature information"
    ))
    ## Read the feature information
    feature_info <-
        rtracklayer::import(file_retrieve(url = file_locate_url_annotation(type = type, organism = organism, annotation = annotation, recount3_url = recount3_url), bfc = bfc))


    message(
        paste(
            Sys.time(),
            "downloading and reading the counts:",
            nrow(metadata),
            "samples across",
            length(feature_info),
            "features."
        )
    )
    counts <- read_counts(file_retrieve(
        url = file_locate_url(
            project = project,
            project_home = project_home,
            type = type,
            organism = organism,
            annotation = annotation,
            recount3_url = recount3_url
        ),
        bfc = bfc
    ))

    ## Build the RSE object
    message(paste(
        Sys.time(),
        "construcing the RangedSummarizedExperiment (rse) object"
    ))
    rse <- SummarizedExperiment::SummarizedExperiment(
        assays = list(counts = counts),
        colData = S4Vectors::DataFrame(metadata, check.names = FALSE),
        rowRanges = feature_info
    )
    return(rse)
}