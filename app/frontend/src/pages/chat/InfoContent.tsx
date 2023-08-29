// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useEffect, useState } from "react";
import { Text } from "@fluentui/react";
import { getInfoData, GetInfoResponse } from "../../api";

interface Props {
    className?: string;
}

export const InfoContent = ({ className }: Props) => {
    const [infoData, setInfoData] = useState<GetInfoResponse | null>(null);

    async function fetchInfoData() {
        console.log("InfoContent 1");
        try {
            const fetchedInfoData = await getInfoData();
            setInfoData(fetchedInfoData);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchInfoData();
    }, []);

    return (
        <div>
            <Text>Azure OpenAI model used: {infoData?.AZURE_OPENAI_CHATGPT_DEPLOYMENT}</Text>
        </div>
    );
};