// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink, Link } from "react-router-dom";
import hwd from "../../assets/hwd.png";
import { WarningBanner } from "../../components/WarningBanner/WarningBanner";
import styles from "./Layout.module.css";
import { Title } from "../../components/Title/Title";
import { getFeatureFlags, GetFeatureFlagsResponse } from "../../api";
import { useEffect, useState } from "react";

export const Layout = () => {
    const [featureFlags, setFeatureFlags] = useState<GetFeatureFlagsResponse | null>(null);

    async function fetchFeatureFlags() {
        try {
            const fetchedFeatureFlags = await getFeatureFlags();
            setFeatureFlags(fetchedFeatureFlags);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchFeatureFlags();
    }, []);

    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <WarningBanner />
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={hwd} alt="BSP HealthCare Plan 2024" className={styles.headerLogo} />
                        <h3 className={styles.headerTitle}><Title /></h3>
                    </div>
                </div>
            </header>

            <Outlet />

            <footer>
                <WarningBanner />
            </footer>
        </div>
    );
};
