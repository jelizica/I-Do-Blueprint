-- Update all tables to use admin couple_id instead of all-zeros UUID

UPDATE guest_list
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE wedding_tasks
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE budget_categories
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE documents
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE wedding_timeline
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE "paymentPlans"
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE notes
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE expenses
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE "vendorInformation"
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE vendor_contacts
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE wedding_milestones
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE reminders
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE gifts_and_owed
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE mood_boards
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE seating_charts
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE color_palettes
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE guest_groups
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';

UPDATE wedding_events
SET couple_id = 'c507b4c9-7ef4-4b76-a71a-63887984b9ab'
WHERE couple_id = '00000000-0000-0000-0000-000000000000';
