# Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
# Delayed::Worker.max_attempts = 10
# Delayed::Worker.max_run_time = 5.minutes
# Delayed::Worker.read_ahead = 10
# Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
# Delayed::Worker.raise_signal_exceptions = :term

# require 'delayed_job_log_setup'
# Delayed::Worker.plugins << DelayedJobLogSetup
