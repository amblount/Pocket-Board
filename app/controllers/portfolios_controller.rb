class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: [:show, :edit, :update, :destroy]
  helper_method :hash_to_array

  # Sample code to use Quandl gem to made api request
  # =====================================================================================
  # @snp = Quandl::Dataset.get("YAHOO/INDEX_GSPC").data(params: { start_date: "2016-01-01", end_date: "2016-04-22" }) # ["date", "open", "high", "low", "close", "volume", "adjusted_close"]
  # @snp_result = yahoo_table(@snp)

  # @nasdaq = Quandl::Dataset.get("NASDAQOMX/COMP").data(params: {start_date: "2016-01-01", end_date: "2016-04-08" }) # ["trade_date", "index_value", "high", "low", "total_market_value", "dividend_market_value"]
  # @nasdaq_result = nasdaq_table(@nasdaq)

  # @dji = Quandl::Dataset.get("YAHOO/INDEX_DJI").data(params: {start_date: "2016-01-01", end_date: "2016-04-22" }) # ["date", "open", "high", "low", "close", "volume", "adjusted_close"]
  # @dji_result = yahoo_table(@dji)

  # @company = "AAPL"
  # @stock = Quandl::Dataset.get("WIKI/#{@company}").data(params: { start_date: "2016-01-01", end_date: "2016-04-22" }) # ["date", "open", "high", "low", "close", "volume", "ex_dividend", "split_ratio", "adj_open", "adj_high", "adj_low", "adj_close", "adj_volume"]
  # @stock_result = stock_table(@stock)

  # GET /portfolios
  # GET /portfolios.json
  def step
    render "steps"
  end

  def index
    if user_signed_in?
      @user = User.find(session[:id])
      @portfolios = @user.portfolios
    end
  end

  # GET /portfolios/1
  # GET /portfolios/1.json
  def show
    # @count = User.find(session[:id]).portfolios.count
    @portfolio = Portfolio.find(params[:id])
    @holdings = @portfolio.holdings

  end

  def fetch

    if request.xhr?
      @portfolio = Portfolio.find(params[:id])
      @holdings = @portfolio.holdings
      @portfolio_data = zippy(@holdings,@portfolio.start_time, @portfolio.end_time)
      @nasdaq= index_data("nasdaq",@portfolio.start_time, @portfolio.end_time)
      @snp= index_data("snp",@portfolio.start_time, @portfolio.end_time)
      @dji= index_data("dji",@portfolio.start_time, @portfolio.end_time)
      @news = []
      @holdings.each do |holding|
        name =Stock.find_by(symbol: holding.symbol).name
        @news << [holding.symbol, nytimes(name, @portfolio.start_time.tr('-',''), @portfolio.end_time.tr('-','') )]
      end
      render :json => {"stocks" => @portfolio_data, "snp" => @snp, "nasdaq" => @nasdaq, "dji" => @dji, "title" => @portfolio.name, "articles" => @news, "holdings" => @holdings }
    end
  end

  def getting_started
  end

  # GET /portfolios/new
  def new
    session[:index] = nil
    session[:stock] = nil
    @user = User.find(session[:id])
    @portfolio = Portfolio.new
    @selections = @user.stocks
    num_of_stocks = StocksUser.where(user_id: session[:id]).count
    num_of_stocks.times{@portfolio.holdings.build}
    @holdings = @portfolio.holdings
  end

  # GET /portfolios/1/edit
  def edit
    @user = User.find(session[:id])
    @portfolio = Portfolio.find(params[:id])
    @selections = @portfolio.holdings
    @holdings = @portfolio.holdings
  end

  # POST /portfolios
  # POST /portfolios.json
  def create

    @portfolio = Portfolio.create(portfolio_params)
    @user = User.find(session[:id])
    @user.portfolios << @portfolio
    StocksUser.where(user_id: session[:id]).destroy_all
    redirect_to portfolios_path


    # respond_to do |format|
    #   if @portfolio.save
    #     format.html { redirect_to @portfolio, notice: 'Portfolio was successfully created.' }
    #     format.json { render :show, status: :created, location: @portfolio }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @portfolio.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /portfolios/1
  # PATCH/PUT /portfolios/1.json
  def update
    @portfolio = Portfolio.find(params[:id])
    @user = User.find(session[:id])
    StocksUser.where(user_id: session[:id]).destroy_all
    @portfolio.update(portfolio_params)

    redirect_to portfolios_path
  end

  # DELETE /portfolios/1
  # DELETE /portfolios/1.json
  def destroy
    @portfolio.destroy
    respond_to do |format|
      format.html { redirect_to portfolios_url, notice: 'Portfolio was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_portfolio
      @portfolio = Portfolio.find(params[:id])
    end

    def portfolio_params
      params.require(:portfolio).permit(:name,:description, :user_id,:start_time,:end_time, :image_url, holdings_attributes: [:id,:symbol, :allocation, :_destroy])
    end

end
