import { get } from "lodash";
import { useState, useEffect, useCallback } from "react";
import recordEvent from "@/services/recordEvent";
import OrgSettings from "@/services/organizationSettings";
import useImmutableCallback from "@/lib/hooks/useImmutableCallback";
import { updateClientConfig } from "@/services/auth";
export default function useOrganizationSettings({ onError }: any) {
    const [settings, setSettings] = useState({});
    const [currentValues, setCurrentValues] = useState({});
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const handleError = useImmutableCallback(onError);
    useEffect(() => {
        // @ts-expect-error ts-migrate(2554) FIXME: Expected 4 arguments, but got 3.
        recordEvent("view", "page", "org_settings");
        let isCancelled = false;
        OrgSettings.get()
            .then(response => {
            if (!isCancelled) {
                const settings = get(response, "settings");
                setSettings(settings);
                setCurrentValues({ ...settings });
                setIsLoading(false);
            }
        })
            .catch(error => {
            if (!isCancelled) {
                handleError(error);
            }
        });
        return () => {
            isCancelled = true;
        };
    }, [handleError]);
    const handleChange = useCallback(changes => {
        setCurrentValues(currentValues => ({ ...currentValues, ...changes }));
    }, []);
    const handleSubmit = useCallback(() => {
        if (!isSaving) {
            setIsSaving(true);
            OrgSettings.save(currentValues)
                .then(response => {
                const settings = get(response, "settings");
                setSettings(settings);
                setCurrentValues({ ...settings });
                updateClientConfig({
                    dateFormat: (currentValues as any).date_format,
                    timeFormat: (currentValues as any).time_format,
                    dateTimeFormat: `${(currentValues as any).date_format} ${(currentValues as any).time_format}`,
                });
            })
                .catch(handleError)
                .finally(() => setIsSaving(false));
        }
    }, [isSaving, currentValues, handleError]);
    return { settings, currentValues, isLoading, isSaving, handleSubmit, handleChange };
}