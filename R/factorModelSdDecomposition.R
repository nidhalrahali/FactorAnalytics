#' Compute factor model standard deviation decomposition
#' 
#' Compute the factor model factor standard deviation decomposition for an
#' asset based on Euler's theorem given factor model parameters. 
#' 
#' The factor model has the form \cr \code{R(t) = beta'F(t) + e(t) = beta.star'F.star(t)}\cr
#' where beta.star = (beta, sig.e)' and F.star(t) = [F(t)', z(t)]'. By Euler's
#' theorem:\cr \code{Sd.fm = sum(cSd.fm) = sum(beta.star*mSd.fm)} \cr
#' 
#' 
#' @param beta.vec k x 1 vector of factor betas with factor names in the
#' rownames.
#' @param factor.cov k x k factor excess return covariance matrix.
#' @param sig2.e scalar, residual variance from factor model.
#' @return an S3 object containing
#' \itemize{
#' \item{Sd.fm} Scalar, std dev based on factor model.
#' \item{mSd.fm} (K+1) x 1 vector of factor marginal contributions to sd.
#' \item{cSd.fm} (K+1) x 1 vector of factor component contributions to sd.
#' \item{pcSd.fm} (K+1) x 1 vector of factor percentage component contributions to sd.
#' }
#' @author Eric Zivot and Yi-An Chen
#' @references 
#' \enumerate{ 
#' \item Hallerback (2003), "Decomposing Portfolio Value-at-Risk: A
#' General Analysis", The Journal of Risk 5/2.
#' \item Yamai and Yoshiba (2002)."Comparative Analyses of Expected Shortfall and Value-at-Risk: Their
#' Estimation Error, Decomposition, and Optimization Bank of Japan.
#' \item Meucci (2007). "Risk Contributions from Generic User-Defined Factors," Risk. 
#' }#' 
#' @examples
#' 
#' # load data from the database
#' data("stat.fm.data")
#' fit.stat <- fitStatisticalFactorModel(sfm.dat,k=2)
#' cov.factors = var(fit.stat$factors)
#' names = colnames(fit.stat$asset.ret)
#' factor.sd.decomp.list = list()
#' for (i in names) {
#'  factor.sd.decomp.list[[i]] =
#'    factorModelSdDecomposition(fit.stat$loadings[,i],
#'                               cov.factors, fit.stat$resid.variance[i])
#' }
#'  
#' @export                                       
#' 
factorModelSdDecomposition <-
function(beta.vec, factor.cov, sig2.e) {

## Remarks:
## The factor model has the form
## R(t) = beta'F(t) + e(t) = beta.star'F.star(t)
## where beta.star = (beta, sig.e)' and F.star(t) = (F(t)', z(t))'
## By Euler's theorem
## sd.fm = sum(cr.fm) = sum(beta*mcr.fm)
  if(is.matrix(beta.vec)) {
    beta.names = c(rownames(beta.vec), "residual")
  } else if(is.vector(beta.vec)) {
    beta.names = c(names(beta.vec), "residual")
  } else {
   stop("beta.vec is not a matrix or a vector")
  }  
  beta.vec = as.vector(beta.vec)
	beta.star.vec = c(beta.vec, sqrt(sig2.e))
	names(beta.star.vec) = beta.names
	factor.cov = as.matrix(factor.cov)
	k.star = length(beta.star.vec)
	k = k.star - 1
	factor.star.cov = diag(k.star)
	factor.star.cov[1:k, 1:k] = factor.cov
	
## compute factor model sd
  sd.fm = as.numeric(sqrt(t(beta.star.vec) %*% factor.star.cov %*% beta.star.vec))
## compute marginal and component contributions to sd
	mcr.fm = (factor.star.cov %*% beta.star.vec)/sd.fm
	cr.fm = mcr.fm * beta.star.vec
	pcr.fm = cr.fm/sd.fm
	rownames(mcr.fm) <- rownames(cr.fm) <- rownames(pcr.fm) <- beta.names
	colnames(mcr.fm) = "MCR"
	colnames(cr.fm) = "CR"
	colnames(pcr.fm) = "PCR"
## return results
	ans = list(Sd.fm = sd.fm,
             mSd.fm = t(mcr.fm),
             cSd.fm = t(cr.fm),
             pcSd.fm = t(pcr.fm))
	return(ans)
}

