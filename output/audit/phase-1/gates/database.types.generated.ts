Connecting to 127.0.0.1 54322
Generated TypeScript is unformatted. Format it with:
  npx oxfmt <generated-file.ts>

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "audit_log": {
                  Row: {
                    "action": string,"actor_id": string | null,"branch_id": string | null,"changed_fields": NonNullable<Json>,"created_at": string,"entity_id": string | null,"entity_type": string,"id": number,"tenant_id": string
                  }
                  Insert: {
                    "action": string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type": string,"id"?: never,"tenant_id": string
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type"?: string,"id"?: never,"tenant_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "audit_log_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "audit_log_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"blocked_time_types": {
                  Row: {
                    "color": string,"created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "blocked_time_types_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"branch_opening_hours": {
                  Row: {
                    "branch_id": string,"closes_at": string,"created_at": string,"day_of_week": number,"id": string,"is_closed": boolean,"opens_at": string,"seq": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"closes_at": string,"created_at"?: string,"day_of_week": number,"id"?: string,"is_closed"?: boolean,"opens_at": string,"seq"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"closes_at"?: string,"created_at"?: string,"day_of_week"?: number,"id"?: string,"is_closed"?: boolean,"opens_at"?: string,"seq"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branch_opening_hours_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"branches": {
                  Row: {
                    "address": string | null,"created_at": string,"enabled_payment_methods": (string)[],"first_day_of_week": number,"id": string,"invoice_prefix": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"phone": string | null,"receipt_footer_ar": string | null,"receipt_footer_en": string | null,"receipt_header_ar": string | null,"receipt_header_en": string | null,"slot_step_minutes": number,"tenant_id": string,"time_format": number,"timezone": string,"tip_presets_percent": (number)[],"tips_enabled": boolean,"updated_at": string
                  }
                  Insert: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id": string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Update: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id"?: string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branches_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"cancellation_reasons": {
                  Row: {
                    "created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "cancellation_reasons_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"closed_periods": {
                  Row: {
                    "branch_id": string,"created_at": string,"ends_on": string,"id": string,"name_ar": string | null,"name_en": string | null,"starts_on": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"ends_on": string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on": string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"ends_on"?: string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "closed_periods_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"currencies": {
                  Row: {
                    "code": string,"is_active": boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol": string | null
                  }
                  Insert: {
                    "code": string,"is_active"?: boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol"?: string | null
                  }
                  Update: {
                    "code"?: string,"is_active"?: boolean,"minor_exponent"?: number,"name_ar"?: string,"name_en"?: string,"symbol"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"idempotency_keys": {
                  Row: {
                    "created_at": string,"function_name": string,"id": string,"key": string,"request_hash": string,"response_body": Json | null,"response_status": number | null,"status": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"function_name": string,"id"?: string,"key": string,"request_hash": string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"function_name"?: string,"id"?: string,"key"?: string,"request_hash"?: string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "idempotency_keys_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"invoice_counters": {
                  Row: {
                    "branch_id": string,"created_at": string,"id": string,"kind": string,"next_number": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"id"?: string,"kind": string,"next_number"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"id"?: string,"kind"?: string,"next_number"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "invoice_counters_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"memberships": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"is_active": boolean,"role": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"user_id": string
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"user_id": string
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "memberships_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "memberships_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"plan_features": {
                  Row: {
                    "created_at": string,"feature": string,"plan_code": string
                  }
                  Insert: {
                    "created_at"?: string,"feature": string,"plan_code": string
                  }
                  Update: {
                    "created_at"?: string,"feature"?: string,"plan_code"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "plan_features_plan_code_fkey"
      columns: ["plan_code"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                },"plans": {
                  Row: {
                    "code": string,"created_at": string,"is_active": boolean,"name_ar": string,"name_en": string,"updated_at": string
                  }
                  Insert: {
                    "code": string,"created_at"?: string,"is_active"?: boolean,"name_ar": string,"name_en": string,"updated_at"?: string
                  }
                  Update: {
                    "code"?: string,"created_at"?: string,"is_active"?: boolean,"name_ar"?: string,"name_en"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"full_name": string,"id": string,"locale": string,"phone": string | null,"updated_at": string
                  }
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name": string,"id": string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name"?: string,"id"?: string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"settings": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"key": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"value": NonNullable<Json>
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"value": NonNullable<Json>
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"value"?: NonNullable<Json>
                  }
                  Relationships: [
                    {
      foreignKeyName: "settings_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "settings_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"tenants": {
                  Row: {
                    "created_at": string,"currency_code": string,"default_locale": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"plan": string,"slug": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"plan"?: string,"slug": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"plan"?: string,"slug"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "tenants_currency_code_fkey"
      columns: ["currency_code"]
isOneToOne: false
      referencedRelation: "currencies"
      referencedColumns: ["code"]
    },{
      foreignKeyName: "tenants_plan_fkey"
      columns: ["plan"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "apply_membership_change":
{ Args: { "p_action": string,"p_actor": string,"p_branch_id"?: string,"p_membership_id"?: string,"p_role"?: string,"p_tenant_id": string,"p_user_id"?: string }; Returns: string
                           },
"archive_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"authorize_branch":
{ Args: { "p_branch_id": string,"p_roles": (string)[] }; Returns: string
                           },
"authorize_tenant_owner":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"can_grant_role":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"colleague_profiles":
{ Args: { "p_tenant_id": string }; Returns: {
              "avatar_url": string,"full_name": string,"id": string
            }[]
                           },
"create_branch":
{ Args: { "p_branch": Json,"p_hours"?: Json,"p_tenant_id": string }; Returns: string
                           },
"current_branch_scope":
{ Args: { "p_tenant_id": string }; Returns: string[]
                           },
"current_tenant_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"default_branch_hours":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"delete_closed_period":
{ Args: { "p_id": string }; Returns: undefined
                           },
"find_user_id_by_email":
{ Args: { "p_email": string }; Returns: string
                           },
"has_tenant_role":
{ Args: { "p_branch_id": string,"p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"has_tenant_role_any_branch":
{ Args: { "p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"holds_membership_authority":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"is_valid_timezone":
{ Args: { "p_timezone": string }; Returns: boolean
                           },
"jsonb_text_array":
{ Args: { "p_value": Json }; Returns: (string)[]
                           },
"list_tenant_members":
{ Args: { "p_tenant_id": string }; Returns: {
              "all_branches": boolean,"branch_id": string,"created_at": string,"email": string,"full_name": string,"invite_pending": boolean,"is_active": boolean,"membership_id": string,"role": string,"user_id": string
            }[]
                           },
"next_counter_value":
{ Args: { "p_branch_id": string,"p_kind": string }; Returns: number
                           },
"provision_branch":
{ Args: { "p_branch": Json,"p_hours": Json,"p_requested_by": string,"p_tenant_id": string }; Returns: Json
                           },
"provision_branch_core":
{ Args: { "p_branch": Json,"p_hours": Json,"p_tenant_id": string }; Returns: string
                           },
"provision_tenant":
{ Args: { "p_branch": Json,"p_owner_id": string,"p_requested_by": string,"p_tenant": Json }; Returns: Json
                           },
"replace_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json }; Returns: undefined
                           },
"restore_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"seed_tenant_catalogues":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"set_blocked_time_type_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"set_cancellation_reason_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"tenant_currency_locked":
{ Args: { "p_tenant_id": string }; Returns: boolean
                           },
"tenant_has_feature":
{ Args: { "p_feature": string,"p_tenant_id": string }; Returns: boolean
                           },
"update_branch":
{ Args: { "p_branch_id": string,"p_patch": Json }; Returns: undefined
                           },
"update_tenant_details":
{ Args: { "p_patch": Json,"p_tenant_id": string }; Returns: undefined
                           },
"upsert_blocked_time_type":
{ Args: { "p_color": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_cancellation_reason":
{ Args: { "p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_closed_period":
{ Args: { "p_branch_id": string,"p_ends_on": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_starts_on": string }; Returns: string
                           },
"write_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json,"p_tenant_id": string }; Returns: undefined
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            
          }
        }
} as const
