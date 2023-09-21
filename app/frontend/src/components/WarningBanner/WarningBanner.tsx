// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useEffect, useState } from "react";
import { Text } from "@fluentui/react";
import { Label } from '@fluentui/react/lib/Label';
import { Separator } from '@fluentui/react/lib/Separator';
import { getWarningBanner, GetWarningBanner } from "../../api";

import styles from "./WarningBanner.module.css";

interface Props {
    className?: string;
}

export const WarningBanner = ({ className }: Props) => {
    const [infoData, setWarningBanner] = useState<GetWarningBanner | null>(null);

    async function fetchWarningBanner() {
        console.log("Warning Banner 1");
        try {
            const fetchedWarningBannerInfo = await getWarningBanner();
            if (!fetchedWarningBannerInfo.WARNING_BANNER_TEXT){
                return null;
            }
            
            setWarningBanner(fetchedWarningBannerInfo);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchWarningBanner();
    }, []);

    return (
        <div className={`${styles.warningBanner} ${className ?? ""}`}>
            {infoData?.WARNING_BANNER_TEXT}
        </div>
    );
};