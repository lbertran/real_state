import React from "react";
import { ethers } from "ethers";
import DivisibleAssetArtifact from "../contracts/DivisibleAsset.json";

const provider = new ethers.providers.Web3Provider( window.ethereum);

export function ShowAssetCollection({ assetsCollection }) {
  /* const numbers = [1, 2, 3, 4, 5];
  const listItems = numbers.map((number) =>
    <li>{number}</li>
  ); */
  
  /* await assetsCollection.forEach(async element => {
    let nombre = await getAssetName(element);
    listNames.push(<li>{nombre}</li>);
  }); */
  
  const listItems = assetsCollection.map(asset =>
  <li>{asset.token}</li>
  );

  console.log(listItems);
    
  return (
    <div>
    <p><b>Listado de activos</b></p>
    <ul>{listItems}</ul>
    </div>
  )
}

async function getAssetName(asset){
  let contract = new ethers.Contract(asset.token, DivisibleAssetArtifact.abi, provider);
  let name = await contract.name();
  console.log(contract);
  return name;
}