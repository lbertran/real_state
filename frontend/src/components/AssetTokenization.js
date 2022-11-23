import React from "react";

export function AssetTokenization({ createDivisibleAsset }) {
  return (
    <div>
      <h4>Create Asset</h4>
      <form
        onSubmit={(event) => {
          // This function just calls the transferTokens callback with the
          // form's data.
          event.preventDefault();

          const formData = new FormData(event.target);
          const _initialSupply = formData.get("_initialSupply");
          const name_ = formData.get("name_");
          const symbol_ = formData.get("symbol_");
          const _price = formData.get("_price");
          const _token = formData.get("_token");
          const _maxLTV = formData.get("_maxLTV");
          const _liqThreshold = formData.get("_liqThreshold");
          const _liqFeeProtocol = formData.get("_liqFeeProtocol");
          const _liqFeeSender = formData.get("_liqFeeSender");
          const _borrowThreshold = formData.get("_borrowThreshold");
          const _interestRate = formData.get("_interestRate");

          if (_initialSupply && name_ && symbol_ && _price && _maxLTV && _liqThreshold && _liqFeeProtocol && _liqFeeSender && _borrowThreshold && _interestRate) {
            createDivisibleAsset(_initialSupply, name_, symbol_, _price, _maxLTV , _liqThreshold , _liqFeeProtocol , _liqFeeSender , _borrowThreshold , _interestRate);
          }
        }}
      >
        
        <div className="row">
          <div className="form-group col-sm-3">
            <label>Initial Supply</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_initialSupply"
              required
            />
          </div>
          <div className="form-group col-sm-3">
            <label>Name</label>
            <input className="form-control" type="text" name="name_" required />
          </div>
          <div className="form-group col-sm-3">
            <label>Symbol</label>
            <input className="form-control" type="text" name="symbol_" required />
          </div>
          <div className="form-group col-sm-3">
            <label>Price</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_price"
              required
            />
          </div>
        </div>
        <div className="row">
          <div className="form-group col-sm-3">
            <label>Max LTV</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_maxLTV"
              required
            />
          </div>
          <div className="form-group col-sm-3">
            <label>Liquidation Threshold</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_liqThreshold"
              required
            />
          </div>
          <div className="form-group col-sm-3">
            <label>Protocol Liquidation Fee</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_liqFeeProtocol"
              required
            />
          </div>
            <div className="form-group col-sm-3">
              <label>Sender Liquidation Fee</label>
              <input
                className="form-control"
                type="number"
                step="1"
                name="_liqFeeSender"
                required
              />
            </div>
        </div>
        <div className="row">
            <div className="form-group col-sm-3">
              <label>Borrow Threshold</label>
              <input
                className="form-control"
                type="number"
                step="1"
                name="_borrowThreshold"
                required
              />
            </div>
            <div className="form-group col-sm-3">
              <label>Interest Rate</label>
              <input
                className="form-control"
                type="number"
                step="1"
                name="_interestRate"
                required
              />
            </div>
        </div>
       
        <div className="form-group">
          <input className="btn btn-primary" type="submit" value="Create Asset" />
        </div>
      </form>
    </div>
  );
}
