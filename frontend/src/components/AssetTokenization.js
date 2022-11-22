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

          if (_initialSupply && name_ && symbol_ && _price) {
            createDivisibleAsset(_initialSupply, name_, symbol_, _price);
          }
        }}
      >
        
        <div class="row">
          <div className="form-group col-sm-4">
          <label>Initial Supply</label>
          <input
            className="form-control"
            type="number"
            step="1"
            name="_initialSupply"
            required
          />
        </div>
          <div className="form-group col-sm-4">
            <label>Name</label>
            <input className="form-control" type="text" name="name_" required />
          </div>
          <div className="form-group col-sm-4">
            <label>Symbol</label>
            <input className="form-control" type="text" name="symbol_" required />
          </div>
          <div className="form-group col-sm-4">
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
       
        <div className="form-group">
          <input className="btn btn-primary" type="submit" value="Create Asset" />
        </div>
      </form>
    </div>
  );
}
