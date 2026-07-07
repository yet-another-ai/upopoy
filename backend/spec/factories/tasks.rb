FactoryBot.define do
  factory :task do
    association :project
    title { "Write the first workflow" }
    description { "Capture the smallest valuable Kanban workflow." }
    status { "todo" }
    priority { "medium" }
    deadline { nil }
    estimated_minutes { nil }
    position { 1 }
  end
end
