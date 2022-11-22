import React from "react";

export function CreateLendingProtocol({ createLendingProtocol }) {
  return (
    <div>
      <h4>Create Lending & Borrowing Protocol</h4>
      <form
        onSubmit={(event) => {
          // This function just calls the transferTokens callback with the
          // form's data.
          event.preventDefault();

          const formData = new FormData(event.target);
          const _token = formData.get("_token");
          const _maxLTV = formData.get("_maxLTV");
          const _liqThreshold = formData.get("_liqThreshold");
          const _liqFeeProtocol = formData.get("_liqFeeProtocol");
          const _liqFeeSender = formData.get("_liqFeeSender");
          const _borrowThreshold = formData.get("_borrowThreshold");
          const _interestRate = formData.get("_interestRate");

          if (_token && _maxLTV && _liqThreshold && _liqFeeProtocol && _liqFeeSender && _borrowThreshold && _interestRate) {
            createLendingProtocol(_token, _maxLTV , _liqThreshold , _liqFeeProtocol , _liqFeeSender , _borrowThreshold , _interestRate);
          }
        }}
      >
        <div class="row">
          <div className="form-group col-sm-4">
            <label>Token address</label>
            <input className="form-control" type="text" name="_token" required />
          </div>
          <div className="form-group col-sm-4">
            <label>Max LTV</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_maxLTV"
              required
            />
          </div>
          <div className="form-group col-sm-4">
            <label>Liquidation Threshold</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_liqThreshold"
              required
            />
          </div>
        </div>
        <div class="row">
          <div className="form-group col-sm-4">
            <label>Protocol Liquidation Fee</label>
            <input
              className="form-control"
              type="number"
              step="1"
              name="_liqFeeProtocol"
              required
            />
          </div>
            <div className="form-group col-sm-4">
              <label>Sender Liquidation Fee</label>
              <input
                className="form-control"
                type="number"
                step="1"
                name="_liqFeeSender"
                required
              />
            </div>
            <div className="form-group col-sm-4">
              <label>Borrow Threshold</label>
              <input
                className="form-control"
                type="number"
                step="1"
                name="_borrowThreshold"
                required
              />
            </div>
        </div>
        <div class="row">
            <div className="form-group col-sm-4">
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
          <input className="btn btn-primary" type="submit" value="Create Protocol" />
        </div>
      </form>
    </div>
  );
}
