import { DAPP_NAME, DAPP_ADDRESS, APTOS_FAUCET_URL, APTOS_NODE_URL, MODULE_URL, STATE_SEED } from '../config/constants';
import { useWallet } from '@manahippo/aptos-wallet-adapter';
import { useForm } from "react-hook-form";
import { useState, useEffect } from 'react';
import React from 'react';
import { AptosAccount, WalletClient, HexString, Provider } from '@martiandao/aptos-web3-bip44.js';

import toast, { LoaderIcon } from "react-hot-toast";

type MapData = {
  name: string;
  description: string;
  uri: string;
  size: number;
  map: string;
};

type MapChainData = {
  token_id: string;
} & MapData;

export default function Home() {
  const { account, signAndSubmitTransaction } = useWallet();
  // TODO: refresh page after disconnect.
  const client = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL);
  const [isLoading, setLoading] = useState<boolean>(false);

  const [maps, setMaps] = useState<MapChainData[]>([]);

  const { register, watch, setValue, handleSubmit } = useForm<MapData>();

  const onUpload = (data: MapData) => {
    const { name, description, uri, size, map } = data;

    if (!account) {
      return toast.error("You need to connect wallet");
    }

    const map_data = JSON.parse(map);
    if (map_data.length != size) {
      return toast.error("Map input not matched with size");
    }

    const payload = {
      type: 'entry_function_payload',
      function: DAPP_ADDRESS + '::map_manager::mint_map',
      type_arguments: [],
      arguments: [
        name,
        description,
        uri,
        size,
        map_data
      ],
    };

    signAndSubmitTransaction(payload, { gas_unit_price: 100 }).then((data) => {
      console.log(data)
      toast.success("Mint map successed");
    }).catch((err) => {
      console.log(err);
      toast.error("Mint map failed");
    });
  }

  const loadMaps = async () => {

    if (account && account.address) {
      const provider = new Provider({
        fullnodeUrl: "https://fullnode.testnet.aptoslabs.com/v1/",
        indexerUrl: "https://indexer-testnet.staging.gcp.aptosdev.com/v1/graphql"
      });

      const resourceAddress = await AptosAccount.getResourceAccountAddress(
        DAPP_ADDRESS,
        new TextEncoder().encode(STATE_SEED)
      );

      const tokens = await provider.getTokenOwnedFromCollectionAddress(
        account.address.toString(),
        "0xf427deb33eeb270c90c371612171f68e63304db48bbcd29a4767b48e66f2541e",
        {
          tokenStandard: "v2",
        }
      );

      const maps = tokens.current_token_ownerships_v2.map((t) => {
        const token_data = t.current_token_data;
        const properties = token_data?.token_properties;
        return {
          token_id: token_data?.token_data_id || "",
          name: token_data?.token_name || "",
          uri: token_data?.token_uri || "",
          description: token_data?.token_properties.size || "",
          size: token_data?.token_properties.size || "",
          map: token_data?.token_properties.size || "",
        };
      });
      setMaps(maps);
    }
  }

  useEffect(() => {
    loadMaps();
  }, [
    account
  ])

  return (
    // HERE if u want a background pic
    //  <div className="flex flex-col justify-center items-center bg-[url('/assets/gradient-bg.png')] bg-[length:100%_100%] py-10 px-5 sm:px-0 lg:py-auto max-w-[100vw] ">  
    <div className="flex flex-col justify-center items-center">
      <div className='text-center'>
        <p>
          <b>Module Path: </b>
          <a target="_blank" href={MODULE_URL} className="underline">
            {DAPP_ADDRESS}::{DAPP_NAME}
          </a>
        </p>
        <br></br>


        <div className=''>
          <h1 className='text-lg font-semibold text-left'>My Maps</h1>

          {
            maps.length == 0 ? <p>--- No maps created ---</p>
              : <div className='flex w-full gap-3 flex-col'>
                {
                  maps.map((t, idx) =>
                    <div className='' key={`map-${idx}`}>
                      {t.name}
                    </div>)
                }
              </div>
          }
        </div>

        <br />

        <form onSubmit={handleSubmit(onUpload)} className='w-full flex flex-col gap-2'>

          <input
            placeholder="Map Name"
            className="p-4 input input-bordered input-primary"
            {...register("name")}
          />

          <input
            placeholder="Map Description"
            className="p-4 input input-bordered input-primary"
            {...register("description")}
          />

          <input
            placeholder="Map Uri"
            className="p-4 input input-bordered input-primary"
            {...register("uri")}
          />

          <input
            placeholder="Map Size"
            type='number'
            className="p-4 input input-bordered input-primary"
            {...register("size", {
              valueAsNumber: true
            })}
          />

          <textarea
            placeholder="Map Data"
            className="p-4 textarea input-bordered input-primary"
            rows={10}
            {...register("map")}
          />

          <button type='submit' className={'btn btn-primary font-bold mt-4  text-white rounded p-4 shadow-lg'}>
            Upload Map
          </button>

        </form>

      </div>
    </div>
  );
}
