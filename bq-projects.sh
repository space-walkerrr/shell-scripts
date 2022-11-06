#!/bin/bash
while read project;do
    gcloud asset search-all-iam-policies  --scope=projects/$(gcloud projects describe $project --format="value(projectNumber)") --asset-types='bigquery.*' --flatten='policy.bindings[].members[]'  --format="csv(assetType.segment(index=-1),resource.scope($project),policy.bindings.members,policy.bindings.role,project.regex(t,nomatch='$project'):label=project-id)" > $project_temp.csv
    cat $project_temp.csv | sed -Ee 's/(.*)members/\1memberType,member/' -e 's/,[: ]/,/' -e 's/:/,/' > $project.csv
    rm $project_temp.csv
    awk '
        BEGIN {FS = OFS = ","}
        $1 ~ /Dataset/ {
            split($2,a,"/")
            project = $6
            $2 = project":"a[2]
        }
        1
    ' $project.csv > temp.csv 
    awk '
        BEGIN {FS = OFS = ","}
        $1 ~ /Table/ {
            split($2,a,"/")
            project = $6
            $2 = project":"a[2]"."a[4]
        }
        1
    ' temp.csv > $project.csv
    rm temp.csv
done< <(gcloud compute shared-vpc list-associated-resources --project tsl-datalake --format="csv[no-heading](id)")
