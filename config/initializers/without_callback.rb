def without_callbacks(&block)
  ShadowCal::Application.NO_CALLBACKS = true
  yield
  ShadowCal::Application.NO_CALLBACKS = false
end
