# Push doggy-daycare worker, web, clock
# Same bits, different v2 apps within same space.

cf create-space doggy-space-dev pet-org
cf create-space doggy-space-prod pet-org

cf target -o pet-org -s doggy-space-dev

cf push doggy-daycare-web -c "bundle exec rake startup"
cf push doggy-daycare-worker -c "bundle exec rake worker"
cf push doggy-daycare-clock -c "bundle exec rake clock"

cf create-user-provided-service db-service -p "admin, puppysecrets"
cf create-service db-service silver doggy-db
cf bind-service doggy-db doggy-daycare-web doggy-db
cf bind-service doggy-db doggy-daycare-worker doggy-db
cf bind-service doggy-db doggy-daycare-clock doggy-db

# CI: Run tests against my dev environment

cf copy-source doggy-daycare-web doggy-daycare-web-green -s doggy-space-prod
cf copy-source doggy-daycare-worker doggy-daycare-worker-green -s doggy-space-prod
cf copy-source doggy-daycare-clock doggy-daycare-clock-green -s doggy-space-prod

# CI: Run tests against my prod environment

cf map-route doggy-daycare-web-green pivotal.io --hostname doggy-daycare-web

# Migration

git add db/123456_add_puppy_health
git commit -m "Add puppy_health table"

cf push doggy-daycare-web -c "bundle exec rake startup"
cf push doggy-daycare-worker -c "bundle exec rake worker"
cf push doggy-daycare-clock -c "bundle exec rake clock"

open http://doggy-daycare-web.pivotal.io

# Migration has failed. Attempt to rollback.

git reset head^
git stash

cf push doggy-daycare-web -c "bundle exec rake startup"
cf push doggy-daycare-worker -c "bundle exec rake worker"
cf push doggy-daycare-clock -c "bundle exec rake clock"

# Try the migration again

git add db/234567_add_puppy_health
git commit -m "Add puppy_health table without breaking things"

cf push doggy-daycare-web
cf push doggy-daycare-worker
cf push doggy-daycare-clock

open http://doggy-daycare-web.pivotal.io

# Email blast

