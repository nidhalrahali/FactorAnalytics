#' predict method for FundamentalFactorModel object
#'
#' Generic function of predict method for fitFundamentalFactorModel.
#' 
#' \code{newdata} must be data.frame and contain date variable, asset variable and exact
#' exposures names that are used in fit object by \code{fitFundamentalFactorModel}  
#'
#' @param object fit "FundamentalFactorModel" object 
#' @param newdata An optional data frame in which to look for variables with which to predict. 
#'                If omitted, the fitted values are used. 
#' @param new.assetvar Specify new asset variable in newdata if newdata is provided.
#' @param new.datevar  Speficy new date variable in newdata if newdata is provided. 
#' @method predict FundamentalFactorModel               
#' @export
#' @author Yi-An Chen
#' @examples
#' data(Stock.df)
#' fit.fund <- fitFundamentalFactorModel(exposure.names=c("BOOK2MARKET", "LOG.MARKETCAP")
#'                                      , data=stock,returnsvar = "RETURN",datevar = "DATE",  
#'                                      assetvar = "TICKER",
#'                                      wls = TRUE, regression = "classic", 
#'                                      covariance = "classic", full.resid.cov = FALSE)
#' # If not specify anything, predict() will give fitted value
#' pred.fund <- predict(fit.fund)
#' 
#' # generate random data
#' testdata <- stock[,c("DATE","TICKER")]
#' testdata$BOOK2MARKET <- rnorm(n=42465)
#' testdata$LOG.MARKETCAP <- rnorm(n=42465)
#' pred.fund2 <- predict(fit.fund,testdata,new.assetvar="TICKER",new.datevar="DATE")
#' 
#' 
predict.FundamentalFactorModel <- function(object,newdata,new.assetvar,new.datevar){
 
  # if there is no newdata provided
  # calculate fitted values
   datevar <- as.character(object$datevar)
   assetvar <- as.character(object$assetvar)
   assets = unique(object$data[,assetvar])
   timedates = as.Date(unique(object$data[,datevar]))
   exposure.names <- object$exposure.names
   
  numTimePoints <- length(timedates)
  numExposures <- length(exposure.names)
  numAssets <- length(assets)
  
  f <-  object$factor.returns # T X 3 
  factor.names <- colnames(f) 
 
  predictor <- function(data) {
    fitted <- rep(NA,numAssets)
    for (i in 1:numTimePoints) {
      fit.tmp <- object$beta %*% t(f[i,])
      fitted <- rbind(fitted,t(fit.tmp))
    }
    fitted <- fitted[-1,]
    colnames(fitted) <- assets
    return(fitted)
  } 

  
  
  predictor.new <- function(data,datevar,assetvar) {
  
  
  beta.all <- data[,c(datevar,assetvar,exposure.names)] #  (N * T ) X 4
  names(beta.all)[1:2] <- c("time","assets.names")  
  
  if (factor.names[1] == "Intercept") {
  beta.all$Intercept  <- rep(1,numTimePoints*numAssets) 
  }
  
  ### calculated fitted values
   
  fitted <- rep(NA,numAssets)
  for (i in 1:numTimePoints) {
    beta <- subset(beta.all, time == index(f)[i] & assets.names %in% assets)[,factor.names]
#     beta <- as.matrix(cbind(rep(1,numAssets),beta))
   beta <- as.matrix(beta)    
fit.tmp <- beta %*% t(f[i,])
    fitted <- rbind(fitted,t(fit.tmp))
  }
  fitted <- fitted[-1,]
  colnames(fitted) <- assets
  return(fitted)
  }
  
  if (missing(newdata) || is.null(newdata)) {
   ans <- predictor(object$data)
 } 
  
  # predict returns by newdata
 if (!missing(newdata) && !is.null(newdata))  {
  # check if newdata has the same datevar and assetvar 
 if (class(newdata) != "data.frame"){
   stop("newdata has to be data.frame.")
 } else if ( length(setdiff(unique(newdata$new.assetvar),assets))!= 0 ){
   stop("newAssetvar must have the same assets as assetvar")
 }   # check if newdata has the same data points as beta
else  if (dim(newdata)[1] != numAssets*numTimePoints ) {
    stop("length of newdata has to match numAssets*numTimePoints")
  } else if( length(setdiff(intersect(names(newdata),exposure.names),exposure.names))!=0 ) {
  stop("newdata must have exact the same exposure.names")    
  } else {
  ans <- predictor.new(newdata,new.datevar,new.assetvar) 
  }
 }
return(ans)  
}