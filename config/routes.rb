 Spree::Core::Engine.routes.prepend do
   match '/admin/reports/outstanding' => 'admin/reports#outstanding',  :via  => [:get, :post],
                                                               :as   => 'outstanding_admin_reports'

   match '/admin/reports/sales' => 'admin/reports#sales',  :via  => [:get, :post],
                                                               :as   => 'sales_admin_reports'

   match '/admin/reports/tax' => 'admin/reports#tax',  :via  => [:get, :post],
                                                               :as   => 'tax_admin_reports'

  match '/admin/reports/revenue' => 'admin/reports#revenue',  :via  => [:get, :post],
                                                              :as   => 'revenue_admin_reports'

  match '/admin/reports/count' => 'admin/reports#count',  :via  => [:get, :post],
                                                          :as   => 'count_admin_reports'

  match '/admin/reports/units' => 'admin/reports#units',  :via  => [:get, :post],
                                                          :as   => 'units_admin_reports'

  match '/admin/reports/profit' => 'admin/reports#profit',  :via => [:get, :post],
                                                            :as  => 'profit_admin_reports'


  match '/admin/reports/top_customers' => 'admin/reports#top_customers',  :via  => [:get, :post],
                                                                          :as   => 'top_customers_admin_reports'

  match '/admin/reports/top_products' => 'admin/reports#top_products',  :via  => [:get, :post],
                                                                        :as   =>  'top_products_admin_reports'

  match '/admin/reports/geo_revenue' => 'admin/reports#geo_revenue', :via => [:get, :post],
                                                                      :as => 'geo_revenue_admin_reports'

  match '/admin/reports/geo_units' => 'admin/reports#geo_units', :via => [:get, :post],
                                                                  :as => 'geo_units_admin_reports'

  match '/admin/reports/geo_profit' => 'admin/reports#geo_profit', :via => [:get, :post],
                                                                    :as => 'geo_profit_admin_reports'

  match '/admin/reports/back_in_stock_stats' => 'admin/reports#back_in_stock_stats', :via => [:get, :post],
                                                                    :as => 'back_in_stock_stats_admin_reports'

  match '/admin/reports/past_month_sales' => 'admin/reports#past_month_sales', :via => [:get, :post],
                                                                    :as => 'past_month_sales_admin_reports'

  match "/admin/reports/dashboard" => "admin/advanced_report_overview#index", :as => 'dashboard_admin_reports'
end
